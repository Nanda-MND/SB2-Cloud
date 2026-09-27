/*======================================================================
  Customer receivable must INCLUDE bank fee (AddAmount).

  Opening / outstanding for a sale:
      TotalAmount + ISNULL(AddAmount,0) - ISNULL(PaidAmount,0)

  After customer money-in (receipt / settlement) clears the fee, post
  Credit under account name ဘဏ်ဝန်ဆောင်ခ (Bank Charges income/clearing).

  Patches dbo.CustomerBalanceDetail (and GetCustomerBalance if present).
======================================================================*/
SET NOCOUNT ON;

DECLARE @names TABLE (Name sysname PRIMARY KEY);
INSERT INTO @names(Name) VALUES
 (N'CustomerBalanceDetail'),
 (N'GetCustomerBalance'),
 (N'CustomerOutstand'),
 (N'UpdateCustomerAging');

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
        PRINT '[SKIP] dbo.' + @name + ' no definition';
        FETCH NEXT FROM c INTO @name;
        CONTINUE;
    END

    SET @def = REPLACE(@def, N'CREATE PROCEDURE', N'CREATE OR ALTER PROCEDURE');
    SET @def = REPLACE(@def, N'create procedure', N'CREATE OR ALTER PROCEDURE');
    SET @def = REPLACE(@def, N'CREATE FUNCTION', N'CREATE OR ALTER FUNCTION');
    SET @def = REPLACE(@def, N'create function', N'CREATE OR ALTER FUNCTION');

    /*
      Expand sale receivable that used TotalAmount alone.
      Prefer: ISNULL(TotalAmount,0) + ISNULL(AddAmount,0)
      Avoid double-adding if already present.
    */
    IF @def NOT LIKE N'%TotalAmount%AddAmount%'
       AND @def NOT LIKE N'%AddAmount%TotalAmount%'
    BEGIN
        -- Common sale side of customer ledger
        SET @def = REPLACE(@def,
            N'ISNULL(H.TotalAmount,0) - ISNULL(H.PaidAmount,0)',
            N'ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0) - ISNULL(H.PaidAmount,0)');
        SET @def = REPLACE(@def,
            N'H.TotalAmount - H.PaidAmount',
            N'ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0) - ISNULL(H.PaidAmount,0)');
        SET @def = REPLACE(@def,
            N'ISNULL(TotalAmount,0) - ISNULL(PaidAmount,0)',
            N'ISNULL(TotalAmount,0) + ISNULL(AddAmount,0) - ISNULL(PaidAmount,0)');
    END
    ELSE
        PRINT '[INFO] dbo.' + @name + ' already references TotalAmount/AddAmount together';

    /*
      Receipt clearing of fee → Credit "ဘဏ်ဝန်ဆောင်ခ"
      If definition has no such label, print hint (manual add may be required).
    */
    IF @def NOT LIKE N'%ဘဏ်ဝန်ဆောင်ခ%'
        PRINT '[HINT] dbo.' + @name + ': after money-in, Credit fee under ဘဏ်ဝန်ဆောင်ခ if not already coded.';

    BEGIN TRY
        EXEC sys.sp_executesql @def;
        PRINT '[OK] Patched dbo.' + @name;
    END TRY
    BEGIN CATCH
        PRINT '[FAIL] dbo.' + @name + ': ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM c INTO @name;
END
CLOSE c; DEALLOCATE c;

PRINT '[DONE] CustomerBalanceDetail_IncludeAddAmount';
GO
