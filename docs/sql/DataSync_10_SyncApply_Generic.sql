/*
  Generic sync apply - works for ANY dbo table registered in SyncConfig.
  Install on BOTH Local and Cloud.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.SyncApply_Generic', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_Generic;
GO

CREATE PROCEDURE dbo.SyncApply_Generic
    @Source             varchar(10),
    @TableName          sysname,
    @PayloadJson        nvarchar(max),
    @PrimaryKeyJson     nvarchar(500),
    @RemoteModifiedAt   datetime2(3),
    @Operation          char(1) = NULL,
    @OutboxID           bigint = NULL,
    @ConflictLogged     bit OUTPUT,
    @Applied            bit OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET @ConflictLogged = 0;
    SET @Applied = 0;

    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = @TableName AND IsEnabled = 1)
    BEGIN
        RAISERROR(N'SyncApply_Generic: table %s not enabled in SyncConfig.', 16, 1, @TableName);
        RETURN;
    END

    DECLARE @obj int = OBJECT_ID(QUOTENAME(@TableName));
    IF @obj IS NULL
    BEGIN
        RAISERROR(N'SyncApply_Generic: table %s not found.', 16, 1, @TableName);
        RETURN;
    END

    DECLARE @pk sysname;
    SELECT TOP 1 @pk = c.name
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @obj AND i.is_primary_key = 1
    ORDER BY ic.key_ordinal;

    IF @pk IS NULL
    BEGIN
        RAISERROR(N'SyncApply_Generic: no PK on %s.', 16, 1, @TableName);
        RETURN;
    END

    DECLARE @pkVal sql_variant = JSON_VALUE(@PrimaryKeyJson, '$.' + @pk);
    DECLARE @pkSql nvarchar(200) = CONVERT(nvarchar(200), @pkVal, 126);

    DECLARE @pkType sysname;
    SELECT TOP 1 @pkType = ty.name
    FROM sys.columns c
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE c.object_id = @obj AND c.name = @pk;

    IF @pkType IS NULL
    BEGIN
        RAISERROR(N'SyncApply_Generic: PK type missing on %s.', 16, 1, @TableName);
        RETURN;
    END

    -- JSON_VALUE is nvarchar. Comparing that sql_variant to an int PK throws
    -- ("Implicit conversion from data type sql_variant") and leaves Op=D Pending.
    -- Head Op=D stays a soft IsDeleted update. Detail Op=D stays a hard DELETE.
    DECLARE @pkPred nvarchar(400) =
        QUOTENAME(@pk) + N' = TRY_CAST(JSON_VALUE(@pkjson, ''$.' + REPLACE(@pk, N'''', N'''''') + N''') AS ' + @pkType + N')';

    IF @Source = 'Cloud'
    BEGIN
        IF EXISTS (
            SELECT 1 FROM dbo.SyncOutbox o WITH (NOLOCK)
            WHERE o.Direction = N'L2C'
              AND o.TableName = @TableName
              AND o.PrimaryKeyJson = @PrimaryKeyJson
              AND o.Status IN (N'Pending', N'Syncing')
        )
        BEGIN
            INSERT INTO dbo.SyncConflictLog (Direction, TableName, PrimaryKeyJson, Resolution,
                RemoteModifiedAt, RemotePayloadJson, Message)
            VALUES (N'C2L', @TableName, @PrimaryKeyJson, N'LocalWinsSkipped',
                @RemoteModifiedAt, @PayloadJson,
                N'Local outbox has pending L2C changes; cloud update skipped.');
            SET @ConflictLogged = 1;
            RETURN;
        END
    END

    -- Resolve inbound delete flag early (needed for LocalWins soft-delete exception).
    DECLARE @isDelete bit = CASE WHEN @Operation = 'D' THEN 1 ELSE 0 END;
    IF @isDelete = 0 AND COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL
        SET @isDelete = ISNULL(TRY_CAST(JSON_VALUE(@PayloadJson, '$.IsDeleted') AS bit), 0);
    IF @isDelete = 0 AND COL_LENGTH(@TableName, 'Deleted') IS NOT NULL
        SET @isDelete = CASE WHEN ISNULL(TRY_CAST(JSON_VALUE(@PayloadJson, '$.Deleted') AS bit), 0) <> 0 THEN 1 ELSE 0 END;

    IF @Source = 'Cloud' AND COL_LENGTH(@TableName, 'SyncModifiedAt') IS NOT NULL
    BEGIN
        DECLARE @localMod datetime2(3);
        DECLARE @chk nvarchar(max) = N'SELECT @m = SyncModifiedAt FROM ' + QUOTENAME(@TableName) +
            N' WHERE ' + @pkPred;
        EXEC sp_executesql @chk, N'@m datetime2(3) OUTPUT, @pkjson nvarchar(500)',
            @m = @localMod OUTPUT, @pkjson = @PrimaryKeyJson;
        IF @localMod IS NOT NULL AND @localMod > @RemoteModifiedAt
        BEGIN
            -- Cloud-zone IDs (>= 2e9) are Cloud-authored. Timestamp LocalWins permanently
            -- blocked Purchase C2L while L2C still worked. Pending L2C still wins (above).
            DECLARE @cloudZoneId bigint = TRY_CAST(@pkVal AS bigint);
            DECLARE @isCloudZonePk bit = CASE WHEN @cloudZoneId IS NOT NULL AND @cloudZoneId >= 2000000000 THEN 1 ELSE 0 END;

            -- Soft-deleted Local zombie must not permanently block Cloud active rows.
            DECLARE @localSoftDeleted bit = 0;
            IF COL_LENGTH(@TableName, 'Deleted') IS NOT NULL OR COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL
            BEGIN
                DECLARE @softSql nvarchar(max) = N'SELECT @s = CASE WHEN 1=0';
                IF COL_LENGTH(@TableName, 'Deleted') IS NOT NULL
                    SET @softSql += N' OR ISNULL(Deleted,0) <> 0';
                IF COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL
                    SET @softSql += N' OR ISNULL(IsDeleted,0) <> 0';
                SET @softSql += N' THEN 1 ELSE 0 END FROM ' + QUOTENAME(@TableName) +
                    N' WHERE ' + @pkPred;
                EXEC sp_executesql @softSql, N'@s bit OUTPUT, @pkjson nvarchar(500)',
                    @s = @localSoftDeleted OUTPUT, @pkjson = @PrimaryKeyJson;
            END

            IF @isCloudZonePk = 0 AND NOT (@localSoftDeleted = 1 AND @isDelete = 0)
            BEGIN
                INSERT INTO dbo.SyncConflictLog (Direction, TableName, PrimaryKeyJson, Resolution,
                    RemoteModifiedAt, LocalModifiedAt, RemotePayloadJson, Message)
                VALUES ('C2L', @TableName, @PrimaryKeyJson, 'LocalWinsSkipped',
                    @RemoteModifiedAt, @localMod, @PayloadJson,
                    N'Local row is newer; cloud change skipped.');
                SET @ConflictLogged = 1;
                RETURN;
            END
        END
    END

    EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;

    IF @isDelete = 1
    BEGIN
        -- Detail lines: ERP UI issues physical DELETE and reloads WITHOUT IsDeleted filter.
        -- Soft-delete on apply left ghost rows on the other side ("detail delete does not sync").
        DECLARE @hardDeleteDetail bit = CASE WHEN @TableName LIKE N'%Detail' THEN 1 ELSE 0 END;

        IF @hardDeleteDetail = 0 AND COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL
        BEGIN
            DECLARE @delSql nvarchar(max) = N'UPDATE ' + QUOTENAME(@TableName) + N' SET IsDeleted = 1';
            IF COL_LENGTH(@TableName, 'Deleted') IS NOT NULL SET @delSql += N', Deleted = 1';
            IF COL_LENGTH(@TableName, 'DeletedAt') IS NOT NULL SET @delSql += N', DeletedAt = @ts';
            IF COL_LENGTH(@TableName, 'SyncModifiedAt') IS NOT NULL SET @delSql += N', SyncModifiedAt = @ts';
            IF COL_LENGTH(@TableName, 'SyncOrigin') IS NOT NULL
                SET @delSql += N', SyncOrigin = ' + CASE WHEN @Source = 'Local' THEN N'1' ELSE N'2' END;
            SET @delSql += N' WHERE ' + @pkPred;
            EXEC sp_executesql @delSql, N'@ts datetime2(3), @pkjson nvarchar(500)',
                @ts = @RemoteModifiedAt, @pkjson = @PrimaryKeyJson;
            -- Soft-delete no-op (0 rows) must not report Applied for C2L.
            IF @Source = N'Cloud' AND @@ROWCOUNT = 0
            BEGIN
                DECLARE @softExists bit = 0;
                DECLARE @softExistsSql nvarchar(max) = N'
SELECT @x = CASE WHEN EXISTS (
    SELECT 1 FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(@obj)) + N'.' + QUOTENAME(@TableName) + N' t
    WHERE t.' + QUOTENAME(@pk) + N' = TRY_CAST(JSON_VALUE(@pkjson, ''$.' + @pk + N''') AS ' + @pkType + N')
) THEN 1 ELSE 0 END';
                EXEC sp_executesql @softExistsSql,
                    N'@pkjson nvarchar(500), @x bit OUTPUT',
                    @pkjson = @PrimaryKeyJson, @x = @softExists OUTPUT;
                IF @softExists = 0
                BEGIN
                    RAISERROR(
                        N'SyncApply_Generic: C2L soft-delete Applied blocked — row missing for %s PK %s.',
                        16, 1, @TableName, @pkSql);
                    RETURN;
                END
            END
        END
        ELSE
        BEGIN
            -- Hard DELETE for *Detail (and any table without IsDeleted).
            BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;
            DECLARE @hardDel nvarchar(max) = N'DELETE FROM ' + QUOTENAME(@TableName) +
                N' WHERE ' + @pkPred;
            EXEC sp_executesql @hardDel, N'@pkjson nvarchar(500)', @pkjson = @PrimaryKeyJson;
            BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
        END
        SET @Applied = 1;
        GOTO done;
    END

    DECLARE @setList nvarchar(max) = N'';
    DECLARE @insertCols nvarchar(max) = N'';
    DECLARE @insertVals nvarchar(max) = N'';
    DECLARE @col sysname;
    DECLARE @type sysname;
    DECLARE @prec tinyint;
    DECLARE @scale int;
    DECLARE @nullable bit;

    DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT c.name, ty.name, c.precision, c.scale, c.is_nullable
        FROM sys.columns c
        INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        WHERE c.object_id = @obj
          AND c.is_computed = 0
          AND c.is_identity = 0
          AND c.name <> @pk
          AND c.system_type_id NOT IN (34, 35, 99, 189, 241)
          AND c.name NOT IN ('SyncRowVersion', 'SyncModifiedAt', 'SyncModifiedBy', 'SyncOrigin', 'IsDeleted', 'Deleted')
        ORDER BY c.column_id;

    OPEN col_cursor;
    FETCH NEXT FROM col_cursor INTO @col, @type, @prec, @scale, @nullable;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @expr nvarchar(400);
        IF @type = 'bit'
            SET @expr = N'CASE LOWER(JSON_VALUE(@json, ''$.' + @col + ''')) WHEN ''true'' THEN 1 WHEN ''false'' THEN 0 ELSE TRY_CAST(JSON_VALUE(@json, ''$.' + @col + ''') AS bit) END';
        ELSE IF @type IN ('decimal', 'numeric')
            SET @expr = N'TRY_CAST(JSON_VALUE(@json, ''$.' + @col + ''') AS ' + @type + N'(' + CAST(@prec AS nvarchar(3)) + N',' + CAST(@scale AS nvarchar(3)) + N'))';
        ELSE IF @type IN ('int','bigint','smallint','tinyint','float','real','date','datetime','datetime2','smalldatetime','uniqueidentifier')
            SET @expr = N'TRY_CAST(JSON_VALUE(@json, ''$.' + @col + ''') AS ' + @type + N')';
        ELSE IF @type IN ('money','smallmoney')
            SET @expr = N'TRY_CAST(NULLIF(LTRIM(RTRIM(JSON_VALUE(@json, ''$.' + @col + '''))), '''') AS ' + @type + N')';
        ELSE
            SET @expr = N'JSON_VALUE(@json, ''$.' + @col + ''')';

        -- Missing/NULL JSON must not violate NOT NULL (e.g. SaleHead.IsBankCharges).
        IF @nullable = 0 AND @type = 'bit'
            SET @expr = N'ISNULL(' + @expr + N', 0)';

        IF @setList <> N'' SET @setList += N', ';
        SET @setList += QUOTENAME(@col) + N' = ' + @expr;

        FETCH NEXT FROM col_cursor INTO @col, @type, @prec, @scale, @nullable;
    END
    CLOSE col_cursor;
    DEALLOCATE col_cursor;

    IF COL_LENGTH(@TableName, 'SyncModifiedAt') IS NOT NULL BEGIN
        IF @setList <> N'' SET @setList += N', ';
        SET @setList += N'SyncModifiedAt = @ts'; END
    IF COL_LENGTH(@TableName, 'SyncOrigin') IS NOT NULL BEGIN
        IF @setList <> N'' SET @setList += N', ';
        SET @setList += N'SyncOrigin = ' + CASE WHEN @Source = 'Local' THEN N'1' ELSE N'2' END; END
    -- Preserve soft-delete flags from payload (do NOT force 0).
    -- Marker: preserve-soft-delete-flags
    -- Forcing Deleted/IsDeleted=0 on every U undid Head soft-deletes after a later sync.
    IF COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL BEGIN
        IF @setList <> N'' SET @setList += N', ';
        SET @setList += N'IsDeleted = ISNULL(CASE LOWER(JSON_VALUE(@json, ''$.IsDeleted'')) '
            + N'WHEN ''true'' THEN 1 WHEN ''false'' THEN 0 '
            + N'ELSE TRY_CAST(JSON_VALUE(@json, ''$.IsDeleted'') AS bit) END, t.IsDeleted)'; END
    IF COL_LENGTH(@TableName, 'Deleted') IS NOT NULL BEGIN
        IF @setList <> N'' SET @setList += N', ';
        SET @setList += N'Deleted = ISNULL(CASE LOWER(JSON_VALUE(@json, ''$.Deleted'')) '
            + N'WHEN ''true'' THEN 1 WHEN ''false'' THEN 0 '
            + N'ELSE TRY_CAST(JSON_VALUE(@json, ''$.Deleted'') AS int) END, t.Deleted)'; END

    DECLARE @schema sysname = OBJECT_SCHEMA_NAME(@obj);
    DECLARE @qualifiedTable nvarchar(776) = QUOTENAME(@schema) + N'.' + QUOTENAME(@TableName);
    DECLARE @pkWhere nvarchar(400) = N't.' + QUOTENAME(@pk) + N' = TRY_CAST(JSON_VALUE(@pkjson, ''$.' + @pk + N''') AS ' + @pkType + N')';

    DECLARE @rowExists bit = 0;
    DECLARE @existsSql nvarchar(max) = N'
SELECT @x = CASE WHEN EXISTS (
    SELECT 1 FROM ' + @qualifiedTable + N' t WHERE ' + @pkWhere + N'
) THEN 1 ELSE 0 END';
    EXEC sp_executesql @existsSql,
        N'@pkjson nvarchar(500), @x bit OUTPUT',
        @pkjson = @PrimaryKeyJson, @x = @rowExists OUTPUT;

    DECLARE @updRows int = 0;
    DECLARE @insRows int = 0;

    IF @rowExists = 1
    BEGIN
        DECLARE @upd nvarchar(max) = N'
UPDATE t SET ' + @setList + N'
FROM ' + @qualifiedTable + N' t
WHERE ' + @pkWhere;

        EXEC sp_executesql @upd,
            N'@json nvarchar(max), @ts datetime2(3), @pkjson nvarchar(500)',
            @json = @PayloadJson, @ts = @RemoteModifiedAt, @pkjson = @PrimaryKeyJson;
        SET @updRows = @@ROWCOUNT;
    END
    ELSE
    BEGIN
        SET @insertCols = N'';
        SET @insertVals = N'';

        DECLARE @hasIdentity bit = CASE WHEN EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = @obj AND is_identity = 1) THEN 1 ELSE 0 END;

        DECLARE ins_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT c.name, ty.name, c.precision, c.scale, c.is_nullable
            FROM sys.columns c
            INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
            WHERE c.object_id = @obj
              AND c.is_computed = 0
              AND c.system_type_id NOT IN (34, 35, 99, 189, 241)
              AND c.name NOT IN ('SyncRowVersion', 'SyncModifiedAt', 'SyncModifiedBy', 'SyncOrigin', 'IsDeleted', 'Deleted')
            ORDER BY c.column_id;

        OPEN ins_cursor;
        FETCH NEXT FROM ins_cursor INTO @col, @type, @prec, @scale, @nullable;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @type = 'bit'
                SET @expr = N'CASE LOWER(JSON_VALUE(@json, ''$.' + @col + ''')) WHEN ''true'' THEN 1 WHEN ''false'' THEN 0 ELSE TRY_CAST(JSON_VALUE(@json, ''$.' + @col + ''') AS bit) END';
            ELSE IF @type IN ('decimal', 'numeric')
                SET @expr = N'TRY_CAST(JSON_VALUE(@json, ''$.' + @col + ''') AS ' + @type + N'(' + CAST(@prec AS nvarchar(3)) + N',' + CAST(@scale AS nvarchar(3)) + N'))';
            ELSE IF @type IN ('int','bigint','smallint','tinyint','float','real','date','datetime','datetime2','smalldatetime','uniqueidentifier')
                SET @expr = N'TRY_CAST(JSON_VALUE(@json, ''$.' + @col + ''') AS ' + @type + N')';
            ELSE IF @type IN ('money','smallmoney')
                SET @expr = N'TRY_CAST(NULLIF(LTRIM(RTRIM(JSON_VALUE(@json, ''$.' + @col + '''))), '''') AS ' + @type + N')';
            ELSE
                SET @expr = N'JSON_VALUE(@json, ''$.' + @col + ''')';

            IF @nullable = 0 AND @type = 'bit'
                SET @expr = N'ISNULL(' + @expr + N', 0)';

            IF @insertCols <> N'' SET @insertCols += N', ';
            SET @insertCols += QUOTENAME(@col);
            IF @insertVals <> N'' SET @insertVals += N', ';
            SET @insertVals += @expr;

            FETCH NEXT FROM ins_cursor INTO @col, @type, @prec, @scale, @nullable;
        END
        CLOSE ins_cursor;
        DEALLOCATE ins_cursor;

        DECLARE @insCols2 nvarchar(max) = @insertCols;
        DECLARE @insVals2 nvarchar(max) = @insertVals;
        IF COL_LENGTH(@TableName, 'SyncModifiedAt') IS NOT NULL BEGIN
            IF @insCols2 <> N'' BEGIN SET @insCols2 += N', '; SET @insVals2 += N', '; END
            SET @insCols2 += N'SyncModifiedAt'; SET @insVals2 += N'@ts'; END
        IF COL_LENGTH(@TableName, 'SyncOrigin') IS NOT NULL BEGIN
            IF @insCols2 <> N'' BEGIN SET @insCols2 += N', '; SET @insVals2 += N', '; END
            SET @insCols2 += N'SyncOrigin'; SET @insVals2 += CASE WHEN @Source = 'Local' THEN N'1' ELSE N'2' END; END
        IF COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL BEGIN
            IF @insCols2 <> N'' BEGIN SET @insCols2 += N', '; SET @insVals2 += N', '; END
            SET @insCols2 += N'IsDeleted'; SET @insVals2 += N'0'; END
        IF COL_LENGTH(@TableName, 'Deleted') IS NOT NULL BEGIN
            IF @insCols2 <> N'' BEGIN SET @insCols2 += N', '; SET @insVals2 += N', '; END
            SET @insCols2 += N'Deleted'; SET @insVals2 += N'0'; END

        DECLARE @ins nvarchar(max);
        IF @hasIdentity = 1
            SET @ins = N'SET IDENTITY_INSERT ' + @qualifiedTable + N' ON;';

        SET @ins = ISNULL(@ins, N'') + N'
INSERT INTO ' + @qualifiedTable + N' (' + @insCols2 + N')
SELECT ' + @insVals2;

        BEGIN TRY
            EXEC sp_executesql @ins,
                N'@json nvarchar(max), @ts datetime2(3)',
                @json = @PayloadJson, @ts = @RemoteModifiedAt;
            SET @insRows = @@ROWCOUNT;
        END TRY
        BEGIN CATCH
            IF @hasIdentity = 1
                EXEC(N'SET IDENTITY_INSERT ' + @qualifiedTable + N' OFF;');
            THROW;
        END CATCH

        IF @hasIdentity = 1
            EXEC(N'SET IDENTITY_INSERT ' + @qualifiedTable + N' OFF;');

        -- C2L into Local: IDENTITY_INSERT of ID >= 2e9 bumps IDENT_CURRENT into Cloud zone.
        -- Reseed Local identity back to MAX(ID) below Cloud floor so new Local inserts stay low.
        IF @hasIdentity = 1 AND @Source = N'Cloud' AND @insRows > 0
           AND @pkType IN (N'int', N'bigint', N'smallint', N'tinyint')
        BEGIN
            DECLARE @CloudFloor bigint = 2000000000;
            DECLARE @insertedId bigint = TRY_CAST(JSON_VALUE(@PrimaryKeyJson, N'$.' + @pk) AS bigint);
            IF @insertedId IS NOT NULL AND @insertedId >= @CloudFloor
            BEGIN
                DECLARE @maxLocalZone bigint;
                DECLARE @reseedSql nvarchar(max) =
                    N'SELECT @m = ISNULL(MAX(CAST(' + QUOTENAME(@pk) + N' AS bigint)), 0)
                      FROM ' + @qualifiedTable + N'
                      WHERE CAST(' + QUOTENAME(@pk) + N' AS bigint) < @floor';
                EXEC sp_executesql @reseedSql,
                    N'@m bigint OUTPUT, @floor bigint',
                    @m = @maxLocalZone OUTPUT, @floor = @CloudFloor;
                IF @maxLocalZone > 0
                BEGIN
                    DECLARE @reseedCmd nvarchar(max) =
                        N'DBCC CHECKIDENT (' + QUOTENAME(@TableName, N'''') + N', RESEED, '
                        + CAST(@maxLocalZone AS nvarchar(30)) + N') WITH NO_INFOMSGS';
                    EXEC(@reseedCmd);
                END
            END
        END
    END

    IF @updRows = 0 AND @insRows = 0
    BEGIN
        SET @rowExists = 0;
        EXEC sp_executesql @existsSql,
            N'@pkjson nvarchar(500), @x bit OUTPUT',
            @pkjson = @PrimaryKeyJson, @x = @rowExists OUTPUT;
        IF @rowExists = 0
        BEGIN
            RAISERROR(N'SyncApply_Generic: no row updated or inserted for %s PK %s.', 16, 1, @TableName, @pkSql);
            RETURN;
        END
    END

    -- Harden C2L: never report Applied unless the PK row is really present.
    -- (Purchase C2L was Synced on Cloud while Local SyncOrigin=2 / ID>=2e9 stayed empty.)
    IF @Source = N'Cloud'
    BEGIN
        SET @rowExists = 0;
        EXEC sp_executesql @existsSql,
            N'@pkjson nvarchar(500), @x bit OUTPUT',
            @pkjson = @PrimaryKeyJson, @x = @rowExists OUTPUT;
        IF @rowExists = 0
        BEGIN
            RAISERROR(
                N'SyncApply_Generic: C2L Applied blocked — row missing after apply for %s PK %s (upd=%d ins=%d).',
                16, 1, @TableName, @pkSql, @updRows, @insRows);
            RETURN;
        END
    END

    SET @Applied = 1;

done:
    EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;
END
GO

BEGIN TRY
    ALTER AUTHORIZATION ON dbo.SyncApply_Generic TO dbo;
    PRINT 'SyncApply_Generic owner set to dbo.';
END TRY
BEGIN CATCH
    PRINT 'WARN: ALTER AUTHORIZATION skipped: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'DataSync_10_SyncApply_Generic.sql completed.';
GO
