/*======================================================================
  SaleHistory — expose Charges (= AddAmount) + ListviewItem for Sales UI

  Client FillListView uses MenuName = 'Sales' (not 'Sale').
  Injects Charges into dbo.SaleHistory SELECT list when missing.
======================================================================*/
SET NOCOUNT ON;

-- UI column (history grid MenuName)
IF NOT EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'Sales' AND ColumnName = N'Charges')
BEGIN
    INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    VALUES (N'Sales', N'Charges', 110, N'Bank Charges');
    PRINT '[OK] ListviewItem Sales.Charges inserted';
END
ELSE
BEGIN
    UPDATE dbo.ListviewItem
    SET ColumnHeader = N'Bank Charges',
        ColumnWidth = CASE WHEN ISNULL(ColumnWidth, 0) < 90 THEN 110 ELSE ColumnWidth END
    WHERE MenuName = N'Sales' AND ColumnName = N'Charges';
    PRINT '[OK] ListviewItem Sales.Charges updated';
END

-- Legacy alias if any rows used MenuName = Sale
IF NOT EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'Sale' AND ColumnName = N'Charges')
BEGIN
    INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    VALUES (N'Sale', N'Charges', 110, N'Bank Charges');
    PRINT '[OK] ListviewItem Sale.Charges inserted (legacy)';
END

-- Note: live ListviewItem has no SortID — do not reference it (compile error even inside IF).

DECLARE @obj_id int = OBJECT_ID(N'dbo.SaleHistory');
IF @obj_id IS NULL
BEGIN
    PRINT '[FAIL] dbo.SaleHistory not found — add Charges manually after restoring TVF.';
    RETURN;
END

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(@obj_id);
IF @def IS NULL
BEGIN
    PRINT '[FAIL] OBJECT_DEFINITION(SaleHistory) is NULL (encrypted?).';
    RETURN;
END

IF @def LIKE N'%Charges = %AddAmount%'
   OR @def LIKE N'%Charges=ISNULL(H.AddAmount%'
   OR @def LIKE N'%AS Charges%'
   OR @def LIKE N'%Charges = MAX(ISNULL(H.AddAmount%'
BEGIN
    PRINT '[SKIP] SaleHistory already exposes Charges from AddAmount';
    GOTO done_verify;
END

SET @def = REPLACE(@def, N'CREATE FUNCTION', N'CREATE OR ALTER FUNCTION');
SET @def = REPLACE(@def, N'CREATE  FUNCTION', N'CREATE OR ALTER FUNCTION');
SET @def = REPLACE(@def, N'create function', N'CREATE OR ALTER FUNCTION');

DECLARE @before nvarchar(max) = @def;
DECLARE @injected bit = 0;

IF CHARINDEX(N'PaidAmount = ISNULL(H.PaidAmount,0)', @def) > 0
BEGIN
    SET @def = REPLACE(@def,
        N'PaidAmount = ISNULL(H.PaidAmount,0)',
        N'PaidAmount = ISNULL(H.PaidAmount,0), Charges = ISNULL(H.AddAmount,0)');
    SET @injected = 1;
END
ELSE IF CHARINDEX(N'PaidAmount=ISNULL(H.PaidAmount,0)', @def) > 0
BEGIN
    SET @def = REPLACE(@def,
        N'PaidAmount=ISNULL(H.PaidAmount,0)',
        N'PaidAmount=ISNULL(H.PaidAmount,0), Charges = ISNULL(H.AddAmount,0)');
    SET @injected = 1;
END
ELSE IF CHARINDEX(N'H.PaidAmount,', @def) > 0
BEGIN
    DECLARE @p int = CHARINDEX(N'H.PaidAmount,', @def);
    SET @def = STUFF(@def, @p, LEN(N'H.PaidAmount,'),
        N'H.PaidAmount, Charges = ISNULL(H.AddAmount,0),');
    SET @injected = 1;
END
ELSE IF CHARINDEX(N', H.PaidAmount', @def) > 0
BEGIN
    DECLARE @p2 int = CHARINDEX(N', H.PaidAmount', @def);
    DECLARE @end int = @p2 + LEN(N', H.PaidAmount');
    WHILE @end <= LEN(@def) AND SUBSTRING(@def, @end, 1) NOT IN (N',', NCHAR(13), NCHAR(10), N' ')
        SET @end += 1;
    DECLARE @rest nvarchar(20) = LTRIM(SUBSTRING(@def, @end, 20));
    IF LEFT(@rest, 1) NOT IN (N'=', N'<', N'>')
    BEGIN
        SET @def = STUFF(@def, @p2, LEN(N', H.PaidAmount'),
            N', H.PaidAmount, Charges = ISNULL(H.AddAmount,0)');
        SET @injected = 1;
    END
END
ELSE IF CHARINDEX(N'H.Amount,', @def) > 0
BEGIN
    DECLARE @p3 int = CHARINDEX(N'H.Amount,', @def);
    SET @def = STUFF(@def, @p3, LEN(N'H.Amount,'),
        N'H.Amount, Charges = ISNULL(H.AddAmount,0),');
    SET @injected = 1;
END
ELSE IF CHARINDEX(N'Paid as', @def) > 0 OR CHARINDEX(N'Paid=', @def) > 0 OR CHARINDEX(N' AS Paid', @def) > 0
BEGIN
    -- Common pattern: Paid = ISNULL(H.PaidAmount,0)
    IF CHARINDEX(N'Paid = ISNULL(H.PaidAmount,0)', @def) > 0
    BEGIN
        SET @def = REPLACE(@def,
            N'Paid = ISNULL(H.PaidAmount,0)',
            N'Paid = ISNULL(H.PaidAmount,0), Charges = ISNULL(H.AddAmount,0)');
        SET @injected = 1;
    END
END

SET @def = REPLACE(@def,
    N'Charges = ISNULL(H.AddAmount,0), Charges = ISNULL(H.AddAmount,0)',
    N'Charges = ISNULL(H.AddAmount,0)');

IF @injected = 0 OR @def = @before
BEGIN
    PRINT '[WARN] Could not auto-inject Charges into SaleHistory.';
    PRINT 'Manual: ALTER FUNCTION dbo.SaleHistory — add in SELECT:';
    PRINT '  Charges = MAX(ISNULL(H.AddAmount,0))  -- if GROUP BY';
    PRINT '  Charges = ISNULL(H.AddAmount,0)         -- otherwise';
    GOTO done_verify;
END

IF @def LIKE N'%GROUP BY%' OR @def LIKE N'%sum(%' OR @def LIKE N'%SUM(%'
BEGIN
    SET @def = REPLACE(@def,
        N'Charges = ISNULL(H.AddAmount,0)',
        N'Charges = MAX(ISNULL(H.AddAmount,0))');
END

BEGIN TRY
    EXEC sys.sp_executesql @def;
    PRINT '[OK] SaleHistory recreated with Charges column';
END TRY
BEGIN CATCH
    PRINT '[FAIL] Auto-patch SaleHistory failed: ' + ERROR_MESSAGE();
    PRINT 'Manual fix required for dbo.SaleHistory Charges = ISNULL(H.AddAmount,0)';
END CATCH

done_verify:
SELECT
    Item = N'ListviewItem Sales.Charges',
    Status = CASE WHEN EXISTS (
        SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'Sales' AND ColumnName = N'Charges'
    ) THEN N'OK' ELSE N'MISSING' END
UNION ALL
SELECT
    N'SaleHistory.Charges',
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SaleHistory')) LIKE N'%Charges%'
         THEN N'OK' ELSE N'MISSING — paste SaleHistory or fix manually' END;
GO
