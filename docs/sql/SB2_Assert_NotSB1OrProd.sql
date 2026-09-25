/*
  SB2-Cloud runner guard.
  Refuse SB1 and the production cloud host before any bootstrap, backup, restore, or cloud script.
*/
SET NOCOUNT ON;

DECLARE @db sysname = DB_NAME();
DECLARE @srv nvarchar(256) = CONVERT(nvarchar(256), @@SERVERNAME);

IF @db IN (N'SB1', N'SB', N'db_abbe78_warehouse')
   OR @db LIKE N'%abbe78%'
   OR @srv LIKE N'%site4now%'
   OR @srv LIKE N'%SQL1002%'
BEGIN
    RAISERROR(N'STOP: SB2 runners refuse SB1 and the production cloud host.', 16, 1);
    RETURN;
END

PRINT N'OK target DB=' + @db + N' Server=' + @srv;
GO
