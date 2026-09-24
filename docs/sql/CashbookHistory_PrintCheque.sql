/*
  CashbookHistory — expose IncomeExpenseHead.PrintCheque

  Cloud: column may be missing (Local-only add). Add column FIRST, then function.
  Error if skipped: Invalid column name 'PrintCheque'

  Run on CLOUD (and Local if column missing):
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1) Column on IncomeExpenseHead
IF COL_LENGTH(N'dbo.IncomeExpenseHead', N'PrintCheque') IS NULL
BEGIN
    ALTER TABLE dbo.IncomeExpenseHead ADD PrintCheque bit NOT NULL
        CONSTRAINT DF_IncomeExpenseHead_PrintCheque DEFAULT (0);
    PRINT 'Added IncomeExpenseHead.PrintCheque';
END
ELSE
    PRINT 'IncomeExpenseHead.PrintCheque already exists';
GO

-- 2) Function
CREATE OR ALTER FUNCTION [dbo].[CashbookHistory]
(
    @UserID int,
    @FDate datetime,
    @TDate datetime,
    @TypeID int,
    @CustomerID int
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        H.ID,
        Date,
        AutoID,
        DocumentID = (CASE WHEN CashbookTypeID = 4 THEN (SELECT dbo.GetPurDocID(RefID)) ELSE DocumentID END),
        CashbookType = T.Name,
        Account = A.Name,
        H.Remark,
        Currency = CR.Name,
        Printed = ISNULL(H.Printed, 0),
        PrintCheque = ISNULL(H.PrintCheque, 0),
        H.ExgRate,
        H.TotalIncome,
        H.TotalExpense,
        Name = dbo.CustName(H.ID, H.CashbookTypeID)
    FROM IncomeExpenseHead H
    JOIN IncomeExpenseDetail D ON H.ID = D.RefID
    JOIN AccountName A ON H.AccountID = A.ID
    JOIN CashbookType T ON T.ID = H.CashbookTypeID
    JOIN Currency CR ON CurrencyID = CR.ID
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND Date BETWEEN @FDate AND @TDate
      AND UserID = (CASE WHEN ISNULL(@UserID, 0) = 0 THEN UserID ELSE @UserID END)
      AND CashbookTypeID = @TypeID
      AND (
            ISNULL(SourceID, -1) = (CASE WHEN @CustomerID = -1 THEN ISNULL(SourceID, -1) ELSE @CustomerID END)
         OR DetailAccountID = (CASE WHEN @CustomerID = -1 THEN ISNULL(SourceID, -1) ELSE @CustomerID END)
          )
    GROUP BY
        H.ID, Date, AutoID, DocumentID, CashbookTypeID, RefID, T.Name, A.Name,
        H.Remark, CR.Name, H.Printed, H.PrintCheque, H.ExgRate, H.TotalIncome, H.TotalExpense
);
GO

PRINT 'CashbookHistory + PrintCheque ready.';
GO
