/*
  TEST CLOUD ONLY (db_abe8c0_sb2).

  Older head rows can have Deleted=1 while IsDeleted=0 and DeletedAt NULL
  (SaleHead 45634). New deletes already set both flags via tr_*_SoftDeleteSync.
  This pass repairs rows already saved that way. Outbox capture is suppressed
  so the repair does not enqueue Op=D. Do not run on Local SB2.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF DB_NAME() IN (N'SB2', N'SB1', N'SB', N'db_abbe78_warehouse', N'db_abe8c0_erp', N'db_abe8c0_luckyone')
   OR DB_NAME() LIKE N'%warehouse%'
   OR DB_NAME() LIKE N'%luckyone%'
   OR DB_NAME() LIKE N'%SB1%'
BEGIN
    RAISERROR(N'STOP: SB2_Repair_HeadSoftDelete_Flags_CLOUD is Test Cloud only. Refusing Local SB2 / SB1 / production.', 16, 1);
    RETURN;
END

PRINT N'=== Repair head soft-delete flags on ' + DB_NAME() + N' ===';

EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;

DECLARE @t sysname, @sql nvarchar(max), @n int;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.name
    FROM sys.tables t
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'dbo'
    WHERE t.name NOT LIKE N'%Detail'
      AND t.name NOT LIKE N'Sync%'
      AND t.name NOT IN (N'UserStatus', N'ListviewItem', N'ListViewItem')
      AND COL_LENGTH(N'dbo.' + t.name, N'Deleted') IS NOT NULL
      AND COL_LENGTH(N'dbo.' + t.name, N'IsDeleted') IS NOT NULL
    ORDER BY t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'UPDATE dbo.' + QUOTENAME(@t) + N' SET IsDeleted = 1';
    IF COL_LENGTH(N'dbo.' + @t, N'DeletedAt') IS NOT NULL
        SET @sql += N', DeletedAt = COALESCE(DeletedAt, SYSUTCDATETIME())';
    SET @sql += N' WHERE ISNULL(Deleted, 0) <> 0 AND ISNULL(IsDeleted, 0) = 0';
    BEGIN TRY
        EXEC sp_executesql @sql;
        SET @n = @@ROWCOUNT;
        IF @n > 0
            PRINT N'  ' + @t + N' IsDeleted set: ' + CAST(@n AS nvarchar(20));
    END TRY
    BEGIN CATCH
        PRINT N'  ' + @t + N' SKIP: ' + ERROR_MESSAGE();
    END CATCH
    FETCH NEXT FROM cur INTO @t;
END
CLOSE cur;
DEALLOCATE cur;

EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;

IF OBJECT_ID(N'dbo.SaleHead', N'U') IS NOT NULL
BEGIN
    SELECT ID, Deleted, IsDeleted, DeletedAt
    FROM dbo.SaleHead
    WHERE ID = 45634;
END

PRINT N'Expect SaleHead 45634 Deleted=1 IsDeleted=1 DeletedAt not null when that row exists.';
PRINT N'Rows were not deleted. Outbox was not queued.';
GO
