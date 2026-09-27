/*
  SB2-Cloud runner guard for this test run.
  Allows Dev Local SB2 and Test Cloud db_abe8c0_sb2 on sql8006.
  Refuses SB1, SQL1002, db_abbe78_warehouse, and the other account databases.
*/
SET NOCOUNT ON;

DECLARE @db sysname = DB_NAME();
DECLARE @srv nvarchar(256) = CONVERT(nvarchar(256), @@SERVERNAME);

IF @db IN (N'SB1', N'SB', N'db_abbe78_warehouse', N'db_abe8c0_erp', N'db_abe8c0_luckyone')
   OR @db LIKE N'%abbe78%'
   OR @srv LIKE N'%SQL1002%'
   OR @srv LIKE N'%sql8020%'
   OR @srv LIKE N'%sql8010%'
BEGIN
    RAISERROR(N'STOP: refusing SB1, SQL1002, or another account database. This test run uses local\SB2 and sql8006 / db_abe8c0_sb2.', 16, 1);
    RETURN;
END

PRINT N'OK target DB=' + @db + N' Server=' + @srv;
GO
