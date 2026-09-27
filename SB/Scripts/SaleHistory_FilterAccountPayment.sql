/*======================================================================
  SaleHistory Payment filter by AccountID (APM etc.)

  UI cboPayment unions PaymentType IDs with AccountName IDs (SysAcctID 2/6).
  When the selected filter ID is an AccountName.ID (not a PaymentType.ID),
  SaleHistory must match H.AccountID = @PaymentID (any PaymentID).

  Payment display column should show Cash/Credit (PaymentType.Name) only —
  not the bank account short name.

  This script patches OBJECT_DEFINITION(dbo.SaleHistory) with common patterns.
======================================================================*/
SET NOCOUNT ON;

DECLARE @obj_id int = OBJECT_ID(N'dbo.SaleHistory');
IF @obj_id IS NULL
BEGIN
    RAISERROR('dbo.SaleHistory not found.', 16, 1);
    RETURN;
END

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(@obj_id);
IF @def IS NULL
BEGIN
    RAISERROR('OBJECT_DEFINITION(SaleHistory) is NULL.', 16, 1);
    RETURN;
END

SET @def = REPLACE(@def, N'CREATE FUNCTION', N'CREATE OR ALTER FUNCTION');
SET @def = REPLACE(@def, N'CREATE  FUNCTION', N'CREATE OR ALTER FUNCTION');
SET @def = REPLACE(@def, N'create function', N'CREATE OR ALTER FUNCTION');

/*
  Typical old filter:
    (@PaymentID = -1 OR H.PaymentID = @PaymentID)

  Target:
    (
      @PaymentID = -1
      OR H.PaymentID = @PaymentID
      OR (
           NOT EXISTS (SELECT 1 FROM PaymentType PT WHERE PT.ID = @PaymentID)
           AND H.AccountID = @PaymentID
         )
    )
*/
IF @def NOT LIKE N'%AccountID = @PaymentID%'
   AND @def NOT LIKE N'%H.AccountID = @PaymentID%'
BEGIN
    IF @def LIKE N'%@PaymentID = -1 OR H.PaymentID = @PaymentID%'
        SET @def = REPLACE(@def,
            N'@PaymentID = -1 OR H.PaymentID = @PaymentID',
            N'@PaymentID = -1 OR H.PaymentID = @PaymentID OR (NOT EXISTS (SELECT 1 FROM dbo.PaymentType PT WHERE PT.ID = @PaymentID) AND H.AccountID = @PaymentID)');
    ELSE IF @def LIKE N'%@PaymentID=-1 OR H.PaymentID=@PaymentID%'
        SET @def = REPLACE(@def,
            N'@PaymentID=-1 OR H.PaymentID=@PaymentID',
            N'@PaymentID=-1 OR H.PaymentID=@PaymentID OR (NOT EXISTS (SELECT 1 FROM dbo.PaymentType PT WHERE PT.ID = @PaymentID) AND H.AccountID = @PaymentID)');
    ELSE
        PRINT '[WARN] Could not find standard PaymentID filter pattern — review SaleHistory manually.';
END
ELSE
    PRINT '[SKIP] AccountID=@PaymentID filter already present';

/*
  Payment column: prefer PaymentType name (Cash/Credit), not account name.
  Common bad pattern joins AccountName as Payment display when PaymentID is account.
  Ensure SELECT uses PaymentType for Payment label.
*/
-- Soft hint only; avoid aggressive rewrite of aliases.
IF @def LIKE N'%Payment = A.%' OR @def LIKE N'%Payment=A.%'
    PRINT '[HINT] SaleHistory may label Payment from AccountName — prefer PaymentType.Name (Cash/Credit).';

BEGIN TRY
    EXEC sys.sp_executesql @def;
    PRINT '[OK] SaleHistory_FilterAccountPayment applied';
END TRY
BEGIN CATCH
    PRINT '[FAIL] ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO
