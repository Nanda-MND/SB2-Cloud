/*
  Patch GL / GL_ND / GeneralLedgerDetailReport_ND to accept multi Account + AcctGroup filters.

  Prerequisites:
    1) Run AccountFilter_Helper.sql (dbo.fn_AccountInFilter)
    2) Procedures already exist on this database

  What it does (per procedure):
    - Replaces @AccountID int with @Account nvarchar(max), @AcctGroup nvarchar(max)
    - Rewrites single-account CASE filters to dbo.fn_AccountInFilter(...)
    - Rewrites Cash(288) special-case checks
    - Rewrites final Where Ledger* = @AccountID clauses

  App callers (frm_Preview):
    - If SP has @Account → pass @Account / @AcctGroup (full multi-filter)
    - Else → pass legacy @AccountID (first selected / Cash 288) so reports still open

  Deploy helper: docs/sql/Deploy-AccountMultiFilter.ps1

  Run on: SB1 (Local; Cloud if these reports run there).
*/

USE [SB1];
GO
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.fn_AccountInFilter', N'FN') IS NULL
BEGIN
	RAISERROR(N'Run AccountFilter_Helper.sql first (dbo.fn_AccountInFilter missing).', 16, 1);
	RETURN;
END
GO

DECLARE @procs TABLE (Name sysname);
INSERT INTO @procs(Name) VALUES
	(N'GeneralLedgerDetailReport_ND'),
	(N'GL_ND'),
	(N'GL');

DECLARE @name sysname, @src nvarchar(max), @n int;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM @procs;
OPEN c;
FETCH NEXT FROM c INTO @name;
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @src = OBJECT_DEFINITION(OBJECT_ID(N'dbo.' + @name));
	IF @src IS NULL
	BEGIN
		PRINT 'SKIP (missing): dbo.' + @name;
		FETCH NEXT FROM c INTO @name;
		CONTINUE;
	END

	-- Already patched?
	IF @src LIKE N'%@AcctGroup%' AND @src LIKE N'%fn_AccountInFilter%'
	BEGIN
		PRINT 'OK (already patched): dbo.' + @name;
		FETCH NEXT FROM c INTO @name;
		CONTINUE;
	END

	-- CREATE → ALTER
	SET @src = STUFF(@src, CHARINDEX(N'CREATE', @src), 6, N'ALTER');

	-- Param: @AccountID int  →  @Account nvarchar(max) = '', @AcctGroup nvarchar(max) = ''
	SET @src = REPLACE(@src, N'@AccountID int', N'@Account nvarchar(max) = '''', @AcctGroup nvarchar(max) = ''''');
	SET @src = REPLACE(@src, N'@AccountID Int', N'@Account nvarchar(max) = '''', @AcctGroup nvarchar(max) = ''''');
	SET @src = REPLACE(@src, N'@AccountID INT', N'@Account nvarchar(max) = '''', @AcctGroup nvarchar(max) = ''''');

	-- Normalize common spacing variants before CASE rewrites
	SET @src = REPLACE(@src, N'isnull(@AccountID, 0)', N'isnull(@AccountID,0)');
	SET @src = REPLACE(@src, N'ISNULL(@AccountID, 0)', N'isnull(@AccountID,0)');
	SET @src = REPLACE(@src, N'ISNULL(@AccountID,0)', N'isnull(@AccountID,0)');
	SET @src = REPLACE(@src, N'Case When isnull(@AccountID,0)  = 0', N'Case When isnull(@AccountID,0) = 0');
	SET @src = REPLACE(@src, N'CASE WHEN isnull(@AccountID,0) = 0', N'Case When isnull(@AccountID,0) = 0');

	-- Cash special-case (more variants)
	SET @src = REPLACE(@src,
		N'(Case When @AccountID = 288 Then 1 Else 0 End)',
		N'(Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)');
	SET @src = REPLACE(@src,
		N'(Case When @AccountID = 288 Then 1 Else 0 end)',
		N'(Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)');
	SET @src = REPLACE(@src,
		N'(CASE WHEN @AccountID = 288 THEN 1 ELSE 0 END)',
		N'(Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)');

	-- Final where clauses
	SET @src = REPLACE(@src, N'Where LedgerAccountID = @AccountID', N'Where dbo.fn_AccountInFilter(LedgerAccountID, @Account, @AcctGroup) = 1');
	SET @src = REPLACE(@src, N'WHERE LedgerAccountID = @AccountID', N'Where dbo.fn_AccountInFilter(LedgerAccountID, @Account, @AcctGroup) = 1');
	SET @src = REPLACE(@src, N'Where LedgerID = @AccountID', N'Where dbo.fn_AccountInFilter(LedgerID, @Account, @AcctGroup) = 1');
	SET @src = REPLACE(@src, N'WHERE LedgerID = @AccountID', N'Where dbo.fn_AccountInFilter(LedgerID, @Account, @AcctGroup) = 1');

	/*
	  Replace:
	    Col = (Case When isnull(@AccountID,0) = 0 THEN ... ELSE @AccountID end)
	  with:
	    dbo.fn_AccountInFilter(Col, @Account, @AcctGroup) = 1

	  Done with a small loop over common left-side column expressions.
	*/
	DECLARE @cols TABLE (Expr nvarchar(200));
	DELETE FROM @cols;
	INSERT INTO @cols(Expr) VALUES
		(N'D.AccountID'), (N'H.AccountID'), (N'DetailAccountID'), (N'AccountID'),
		(N'd.AccountID'), (N'h.AccountID');

	DECLARE @col nvarchar(200), @needle nvarchar(max), @pos int, @end int, @chunk nvarchar(max), @thenPos int;
	DECLARE cc CURSOR LOCAL FAST_FORWARD FOR SELECT Expr FROM @cols;
	OPEN cc;
	FETCH NEXT FROM cc INTO @col;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Loop until no more matches for this column
		SET @n = 0;
		WHILE @n < 200
		BEGIN
			SET @n = @n + 1;
			SET @needle = @col + N' = (Case When isnull(@AccountID,0)';
			SET @pos = CHARINDEX(@needle, @src);
			IF @pos = 0
			BEGIN
				SET @needle = @col + N' = (Case When isnull(@AccountID,0) ';
				SET @pos = CHARINDEX(N'' + @col + N' = (Case When isnull(@AccountID,0)', @src);
			END
			IF @pos = 0 BREAK;

			SET @end = CHARINDEX(N'ELSE @AccountID end)', @src, @pos);
			IF @end = 0 SET @end = CHARINDEX(N'ELSE @AccountID End)', @src, @pos);
			IF @end = 0 SET @end = CHARINDEX(N'ELSE @AccountID END)', @src, @pos);
			IF @end = 0 BREAK;

			SET @end = @end + LEN(N'ELSE @AccountID end)');
			SET @chunk = SUBSTRING(@src, @pos, @end - @pos);
			SET @src = STUFF(@src, @pos, @end - @pos, N'dbo.fn_AccountInFilter(' + @col + N', @Account, @AcctGroup) = 1');
		END
		FETCH NEXT FROM cc INTO @col;
	END
	CLOSE cc; DEALLOCATE cc;

	-- Safety: refuse to apply if @AccountID still referenced
	IF @src LIKE N'%@AccountID%'
	BEGIN
		PRINT 'FAIL (still has @AccountID — apply manually): dbo.' + @name;
		-- Dump leftover snippets to help manual fix
		DECLARE @p int = CHARINDEX(N'@AccountID', @src);
		IF @p > 0
			PRINT ' near: ' + SUBSTRING(@src, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, 120);
		FETCH NEXT FROM c INTO @name;
		CONTINUE;
	END

	BEGIN TRY
		EXEC sys.sp_executesql @src;
		PRINT 'PATCHED: dbo.' + @name;
	END TRY
	BEGIN CATCH
		PRINT 'ERROR patching dbo.' + @name + N': ' + ERROR_MESSAGE();
	END CATCH

	FETCH NEXT FROM c INTO @name;
END
CLOSE c; DEALLOCATE c;
GO

PRINT 'GL account multi-filter patch finished.';
GO
