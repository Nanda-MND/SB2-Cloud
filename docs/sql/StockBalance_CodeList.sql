/*
  FUTURE: Rolling stock cache + fast CodeList (T-2 days).
  NOT wired in frm_CodeList yet — deploy when ready, then update the form to call StockBalance_CodeList.

  Deploy:
    sqlcmd -S Server\SB1 -d SB1 -U sa -P ... -C -I -i StockBalance_CodeList.sql

  First run:
    EXEC dbo.StockBalance_RefreshBase;

  Nightly SQL Agent:
    EXEC SB1.dbo.StockBalance_RefreshBase;
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.StockBalanceCacheMeta', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockBalanceCacheMeta (
        Id              int           NOT NULL CONSTRAINT PK_StockBalanceCacheMeta PRIMARY KEY DEFAULT (1),
        BaseAsOfDate    date          NULL,
        BaseUserID      int           NOT NULL CONSTRAINT DF_StockBalanceCacheMeta_User DEFAULT (0),
        DaysBack        int           NOT NULL CONSTRAINT DF_StockBalanceCacheMeta_Days DEFAULT (2),
        LastRefreshUtc  datetime2(3)  NULL,
        CONSTRAINT CK_StockBalanceCacheMeta_Single CHECK (Id = 1)
    );
    INSERT INTO dbo.StockBalanceCacheMeta (Id, DaysBack) VALUES (1, 2);
END
GO

IF OBJECT_ID('dbo.StockStatus_Base', 'U') IS NULL
BEGIN
    SELECT TOP 0 * INTO dbo.StockStatus_Base FROM dbo.StockStatus;
    IF COL_LENGTH('dbo.StockStatus_Base', 'UserID') IS NOT NULL
        ALTER TABLE dbo.StockStatus_Base DROP COLUMN UserID;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.StockStatus_Base') AND name = 'IX_StockStatus_Base_CodeLoc'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_StockStatus_Base_CodeLoc
        ON dbo.StockStatus_Base (CodeID, LocationID, BrandID)
        INCLUDE (Code, Name, Brand, Qty, Short);
END
GO

IF OBJECT_ID('dbo.StockBalance_RefreshBase', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockBalance_RefreshBase;
GO

CREATE PROCEDURE dbo.StockBalance_RefreshBase
    @DaysBack   int = NULL,
    @BaseUserID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Days int = ISNULL(@DaysBack, (SELECT DaysBack FROM dbo.StockBalanceCacheMeta WHERE Id = 1));
    DECLARE @UserID int = ISNULL(@BaseUserID, (SELECT BaseUserID FROM dbo.StockBalanceCacheMeta WHERE Id = 1));
    DECLARE @TDate date = DATEADD(day, -@Days, CAST(GETDATE() AS date));
    DECLARE @FDate date;
    DECLARE @insertCols nvarchar(max);
    DECLARE @selectCols nvarchar(max);
    DECLARE @sql nvarchar(max);

    SELECT TOP 1 @FDate = CAST(SettingDate AS date) FROM dbo.Setting ORDER BY ID;
    IF @FDate IS NULL SET @FDate = '1900-01-01';

    EXEC dbo.StockBalance @UserID, @FDate, @TDate, N'', N'', N'', N'';
    EXEC dbo.UpdateStockStatusUnit @UserID = @UserID;

    TRUNCATE TABLE dbo.StockStatus_Base;

    SELECT @insertCols = STUFF((
        SELECT N', ' + QUOTENAME(c.name)
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID('dbo.StockStatus_Base')
        ORDER BY c.column_id
        FOR XML PATH(''), TYPE).value(N'.', N'nvarchar(max)'), 1, 2, N'');

    SELECT @selectCols = STUFF((
        SELECT N', ' + N'SS.' + QUOTENAME(c.name)
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID('dbo.StockStatus_Base')
        ORDER BY c.column_id
        FOR XML PATH(''), TYPE).value(N'.', N'nvarchar(max)'), 1, 2, N'');

    SET @sql = N'INSERT INTO dbo.StockStatus_Base (' + @insertCols + N')
SELECT ' + @selectCols + N' FROM dbo.StockStatus SS WHERE SS.UserID = @UserID';

    EXEC sp_executesql @sql, N'@UserID int', @UserID = @UserID;

    UPDATE dbo.StockBalanceCacheMeta
    SET BaseAsOfDate = @TDate, LastRefreshUtc = sysutcdatetime(), DaysBack = @Days, BaseUserID = @UserID
    WHERE Id = 1;
END
GO

IF OBJECT_ID('dbo.StockBalance_EnsureBase', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockBalance_EnsureBase;
GO

CREATE PROCEDURE dbo.StockBalance_EnsureBase
    @AsOfDate date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Days int = (SELECT DaysBack FROM dbo.StockBalanceCacheMeta WHERE Id = 1);
    DECLARE @NeedDate date = DATEADD(day, -@Days, @AsOfDate);
    DECLARE @BaseDate date = (SELECT BaseAsOfDate FROM dbo.StockBalanceCacheMeta WHERE Id = 1);
    IF @BaseDate IS NULL OR @BaseDate < @NeedDate
        EXEC dbo.StockBalance_RefreshBase @DaysBack = @Days;
END
GO

IF OBJECT_ID('dbo.StockBalance_CodeList', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockBalance_CodeList;
GO

CREATE PROCEDURE dbo.StockBalance_CodeList
    @UserID     int,
    @FDate      datetime,
    @TDate      datetime,
    @Code       nvarchar(100),
    @GroupID    nvarchar(100) = N'',
    @TypeID     nvarchar(100) = N'',
    @Location   nvarchar(100) = N''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AsOf date = CAST(@TDate AS date);
    DECLARE @Days int = (SELECT DaysBack FROM dbo.StockBalanceCacheMeta WHERE Id = 1);
    DECLARE @RollFrom date = DATEADD(day, -@Days, @AsOf);
    DECLARE @BaseDate date;
    DECLARE @seedCols nvarchar(max);
    DECLARE @seedSelect nvarchar(max);
    DECLARE @mergeCols nvarchar(max);
    DECLARE @mergeSelect nvarchar(max);
    DECLARE @seedSql nvarchar(max);
    DECLARE @mergeSql nvarchar(max);

    EXEC dbo.StockBalance_EnsureBase @AsOfDate = @AsOf;
    SELECT @BaseDate = BaseAsOfDate FROM dbo.StockBalanceCacheMeta WHERE Id = 1;
    IF @RollFrom < @BaseDate SET @RollFrom = @BaseDate;

    DELETE FROM dbo.StockStatus WHERE UserID = @UserID;

    IF EXISTS (SELECT 1 FROM dbo.StockStatus_Base)
    BEGIN
        SELECT @seedCols = STUFF((
            SELECT N', ' + QUOTENAME(c.name)
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID('dbo.StockStatus_Base')
            ORDER BY c.column_id
            FOR XML PATH(''), TYPE).value(N'.', N'nvarchar(max)'), 1, 2, N'');

        SELECT @seedSelect = STUFF((
            SELECT N', ' + N'B.' + QUOTENAME(c.name)
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID('dbo.StockStatus_Base')
            ORDER BY c.column_id
            FOR XML PATH(''), TYPE).value(N'.', N'nvarchar(max)'), 1, 2, N'');

        SET @seedSql = N'INSERT INTO dbo.StockStatus (UserID, ' + @seedCols + N')
SELECT @UserID, ' + @seedSelect + N' FROM dbo.StockStatus_Base B';
        EXEC sp_executesql @seedSql, N'@UserID int', @UserID = @UserID;
    END

    SELECT * INTO #BaseSeed FROM dbo.StockStatus WHERE UserID = @UserID;

    -- Fast path: only last N days (default 2)
    EXEC dbo.StockBalance @UserID, @RollFrom, @TDate, @Code, @GroupID, @TypeID, @Location;

    IF EXISTS (SELECT 1 FROM #BaseSeed)
    BEGIN
        SELECT @mergeCols = STUFF((
            SELECT N', ' + QUOTENAME(c.name)
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID('dbo.StockStatus') AND c.name <> 'UserID'
            ORDER BY c.column_id
            FOR XML PATH(''), TYPE).value(N'.', N'nvarchar(max)'), 1, 2, N'');

        SELECT @mergeSelect = STUFF((
            SELECT N', ' + N'B.' + QUOTENAME(c.name)
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID('dbo.StockStatus') AND c.name <> 'UserID'
            ORDER BY c.column_id
            FOR XML PATH(''), TYPE).value(N'.', N'nvarchar(max)'), 1, 2, N'');

        SET @mergeSql = N'INSERT INTO dbo.StockStatus (UserID, ' + @mergeCols + N')
SELECT @UserID, ' + @mergeSelect + N'
FROM #BaseSeed B
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.StockStatus S
    WHERE S.UserID = @UserID AND S.CodeID = B.CodeID AND S.LocationID = B.LocationID
      AND ISNULL(S.BrandID, 0) = ISNULL(B.BrandID, 0)
)';
        EXEC sp_executesql @mergeSql, N'@UserID int', @UserID = @UserID;
    END

    EXEC dbo.UpdateStockStatusUnit @UserID = @UserID;

    IF @Code <> N''
        DELETE FROM dbo.StockStatus WHERE UserID = @UserID AND Code NOT LIKE @Code + N'%';

    DECLARE @Cols nvarchar(max);
    SELECT @Cols = STUFF((
        SELECT N', ' + QUOTENAME(L.Short)
        FROM dbo.Location L
        WHERE ISNULL(L.Deleted, 0) <> 1
          AND (@Location = N'' OR L.Short = @Location OR CAST(L.ID AS nvarchar(20)) = @Location)
        ORDER BY L.SortID, L.Short
        FOR XML PATH(''), TYPE).value(N'.', N'nvarchar(max)'), 1, 2, N'');

    IF @Cols IS NULL OR LEN(@Cols) = 0
    BEGIN
        SELECT TOP 0 CAST(NULL AS int) AS ID, CAST(NULL AS nvarchar(50)) AS Short,
            CAST(NULL AS nvarchar(200)) AS Name, CAST(NULL AS nvarchar(100)) AS Brand;
        RETURN;
    END

    DECLARE @Sql nvarchar(max) = N'
SELECT * FROM (
    SELECT ID = SS.CodeID, Short = SS.Code, SS.Name, SS.Brand,
           Qty = dbo.GetQtyinUnitRelation(SS.CodeID, SS.Qty), Loc = SS.Short
    FROM dbo.StockStatus SS
    WHERE SS.UserID = @UserID
      AND (@Code = N'''' OR SS.Code LIKE @Code + N''%'')
      AND (@Location = N'''' OR SS.Short = @Location OR CAST(SS.LocationID AS nvarchar(20)) = @Location)
) src
PIVOT ( MAX(Qty) FOR Loc IN (' + @Cols + N') ) pvt
ORDER BY Short';

    EXEC sp_executesql @Sql, N'@UserID int, @Code nvarchar(100), @Location nvarchar(100)',
        @UserID = @UserID, @Code = @Code, @Location = @Location;
END
GO

PRINT 'StockBalance_CodeList + rolling cache deployed.';
PRINT 'Run once: EXEC dbo.StockBalance_RefreshBase;';
GO

/*
  SQL Agent (nightly 02:00):
  EXEC SB1.dbo.StockBalance_RefreshBase;
*/
