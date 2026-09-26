/*======================================================================
  GL / sale bank+cash Debit must EXCLUDE bank fee (AddAmount).

  Correct goods amount for bank Debit:
      Amount - Discount + Tax
   (= SaleHead.TotalAmount when TotalAmount is goods-net-only)

  Patches dbo.GeneralLedgerDetailReport when its body posts / reads sale
  lines using TotalAmount+AddAmount (or similar). Also patches common
  sale-posting helpers if present: SaleGL, InsertSaleGL, UpdateCashbookSale.
======================================================================*/
SET NOCOUNT ON;

DECLARE @names TABLE (Name sysname PRIMARY KEY);
INSERT INTO @names(Name) VALUES
 (N'GeneralLedgerDetailReport'),
 (N'SaleGL'),
 (N'InsertSaleGL'),
 (N'UpdateCashbookSale'),
 (N'CashbookSale');

DECLARE @name sysname, @def nvarchar(max), @id int;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM @names;
OPEN c;
FETCH NEXT FROM c INTO @name;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @id = OBJECT_ID(N'dbo.' + @name);
    IF @id IS NULL
    BEGIN
        PRINT '[SKIP] dbo.' + @name + ' not found';
        FETCH NEXT FROM c INTO @name;
        CONTINUE;
    END

    SET @def = OBJECT_DEFINITION(@id);
    IF @def IS NULL
    BEGIN
        PRINT '[SKIP] dbo.' + @name + ' encrypted / no definition';
        FETCH NEXT FROM c INTO @name;
        CONTINUE;
    END

    SET @def = REPLACE(@def, N'CREATE PROCEDURE', N'CREATE OR ALTER PROCEDURE');
    SET @def = REPLACE(@def, N'CREATE  PROCEDURE', N'CREATE OR ALTER PROCEDURE');
    SET @def = REPLACE(@def, N'create procedure', N'CREATE OR ALTER PROCEDURE');
    SET @def = REPLACE(@def, N'CREATE FUNCTION', N'CREATE OR ALTER FUNCTION');
    SET @def = REPLACE(@def, N'create function', N'CREATE OR ALTER FUNCTION');

    /*
      Replace fee-inclusive debit patterns with goods-net only.
      Common expressions seen in SB-family DBs:
        TotalAmount + ISNULL(AddAmount,0)
        TotalAmount + AddAmount
        ISNULL(TotalAmount,0) + ISNULL(AddAmount,0)
    */
    SET @def = REPLACE(@def,
        N'ISNULL(TotalAmount,0) + ISNULL(AddAmount,0)',
        N'(ISNULL(Amount,0) - ISNULL(Discount,0) + ISNULL(TaxAmount,0))');
    SET @def = REPLACE(@def,
        N'TotalAmount + ISNULL(AddAmount,0)',
        N'(ISNULL(Amount,0) - ISNULL(Discount,0) + ISNULL(TaxAmount,0))');
    SET @def = REPLACE(@def,
        N'TotalAmount+ISNULL(AddAmount,0)',
        N'(ISNULL(Amount,0)-ISNULL(Discount,0)+ISNULL(TaxAmount,0))');
    SET @def = REPLACE(@def,
        N'TotalAmount + AddAmount',
        N'(ISNULL(Amount,0) - ISNULL(Discount,0) + ISNULL(TaxAmount,0))');
    SET @def = REPLACE(@def,
        N'H.TotalAmount + ISNULL(H.AddAmount,0)',
        N'(ISNULL(H.Amount,0) - ISNULL(H.Discount,0) + ISNULL(H.TaxAmount,0))');
    SET @def = REPLACE(@def,
        N'H.TotalAmount + H.AddAmount',
        N'(ISNULL(H.Amount,0) - ISNULL(H.Discount,0) + ISNULL(H.TaxAmount,0))');

    BEGIN TRY
        EXEC sys.sp_executesql @def;
        PRINT '[OK] Patched dbo.' + @name;
    END TRY
    BEGIN CATCH
        PRINT '[FAIL] dbo.' + @name + ': ' + ERROR_MESSAGE();
        PRINT 'Manual rule: bank/cash Debit = Amount - Discount + Tax (no AddAmount).';
    END CATCH

    FETCH NEXT FROM c INTO @name;
END
CLOSE c; DEALLOCATE c;

PRINT '[DONE] GeneralLedgerDetailReport_ExcludeAddAmount';
PRINT 'If live posting still includes fee, inspect sale save trigger / Cashbook insert SP.';
GO
