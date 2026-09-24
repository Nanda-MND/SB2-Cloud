/*
  Shared Account / Account Group multi-select filter for GL-style reports.

  @Account   = comma-separated AccountName.ID (empty = ignore)
  @AcctGroup = comma-separated AcctGroup.ID (used when @Account is empty)

  Rules:
    - both empty          → match all accounts
    - @Account set        → match IDs in list
    - only @AcctGroup set → match accounts whose GroupID is in list

  Run on: SB1 (Local; Cloud if GL reports run there) BEFORE updating GL procedures.
*/

USE [SB1];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fn_AccountInFilter]
(
	@AccountID int,
	@Account nvarchar(max),
	@AcctGroup nvarchar(max)
)
RETURNS bit
AS
BEGIN
	IF ISNULL(@Account, N'') = N'' AND ISNULL(@AcctGroup, N'') = N''
		RETURN 1;

	IF ISNULL(@Account, N'') <> N''
	BEGIN
		IF CHARINDEX(N',' + CAST(@AccountID AS varchar(20)) + N',', N',' + @Account + N',') > 0
			RETURN 1;
		RETURN 0;
	END

	IF EXISTS (
		SELECT 1
		FROM dbo.AccountName A
		WHERE A.ID = @AccountID
		  AND ISNULL(A.Deleted, 0) <> 1
		  AND CHARINDEX(N',' + CAST(A.GroupID AS varchar(20)) + N',', N',' + @AcctGroup + N',') > 0
	)
		RETURN 1;

	RETURN 0;
END
GO

PRINT 'dbo.fn_AccountInFilter created.';
GO
