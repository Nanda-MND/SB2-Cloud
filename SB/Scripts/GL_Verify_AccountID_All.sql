/*======================================================================
  GL Account filter — Select All = @AccountID -1

  Live dbo.GL already supports:
      Where AN.ID = IIF(@AccountID = -1, AN.ID, @AccountID)

  Client bug was: Select All left FilterAccount empty, then AcctiD fell
  back to hidden cbAccount default 288 (Cash in Hand).

  Fix is in SB.exe (frm_Reports): empty / multi FilterAccount → AcctiD = -1.
  No SP change required for Select All.

  This script only verifies the live GL body still has the -1 pattern.
======================================================================*/
USE [SB2];
GO
SET NOCOUNT ON;

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.GL'));
IF @def IS NULL
BEGIN
    PRINT '[FAIL] dbo.GL not found or encrypted';
    RETURN;
END

SELECT
    CheckItem = N'GL supports @AccountID = -1',
    Status = CASE
        WHEN @def LIKE N'%IIF( @AccountID = -1%'
          OR @def LIKE N'%IIF(@AccountID = -1%'
          OR @def LIKE N'%@AccountID = -1%'
        THEN N'OK'
        ELSE N'MISSING — paste/update GL so AN.ID = IIF(@AccountID=-1, AN.ID, @AccountID)'
    END;
GO

PRINT '[INFO] Rebuild/deploy SB.exe for Select All → AcctiD=-1 client fix.';
GO
