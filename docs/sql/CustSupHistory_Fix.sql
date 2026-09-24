/*
  Fix dbo.CustSupHistory — empty history when From/To is Manufacturer (1452/1559)
  or Customer (289) if dbo.GetCustSupName() is incomplete.

  App account map (frm_CustSupTransfer):
    26, 1494  → Supplier
    289       → Customer
    1452,1559 → Manufacturer

  Root cause: INNER JOIN dbo.GetCustSupName() drops rows when TypeID/source
  is missing from that TVF (e.g. ID 118: FromAcctID=1452 Manufacturer).

  Deploy on SB1. Then re-test:
    SELECT * FROM dbo.CustSupHistory(0, '2026-08-01', '2026-09-14', -1, -1, -1);
*/

USE [SB1];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Optional: see what GetCustSupName currently covers
-- SELECT TypeID, Cnt = COUNT(*) FROM dbo.GetCustSupName() GROUP BY TypeID ORDER BY TypeID;
-- SELECT * FROM dbo.GetCustSupName() WHERE TypeID IN (26, 289, 1452, 1494, 1559) AND ID IN (36, 1644);

CREATE OR ALTER FUNCTION [dbo].[CustSupHistory]
(
	@UserID     int,
	@FDate      datetime,
	@TDate      datetime,
	@AccountID  int = -1,
	@CustomerID int = -1,
	@SupplierID int = -1
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		H.ID,
		H.Date,
		H.AutoID,
		H.DocumentID,
		FromAcct =
			CASE
				WHEN H.FromAcctID IN (26, 1494) THEN N'Creditors'
				WHEN H.FromAcctID IN (1452, 1559) THEN N'Creditors(Manufacturer)'
				WHEN H.FromAcctID = 289 THEN N'Debtors'
				ELSE ISNULL(FA.Name, N'')
			END,
		FromName =
			CASE
				WHEN H.FromAcctID IN (26, 1494) THEN SFrom.Name
				WHEN H.FromAcctID IN (1452, 1559) THEN MFrom.Name
				WHEN H.FromAcctID = 289 THEN CFrom.Name
				ELSE NULL
			END,
		ToAcct =
			CASE
				WHEN H.ToAcctID IN (26, 1494) THEN N'Creditors'
				WHEN H.ToAcctID IN (1452, 1559) THEN N'Creditors(Manufacturer)'
				WHEN H.ToAcctID = 289 THEN N'Debtors'
				ELSE ISNULL(TA.Name, N'')
			END,
		ToName =
			CASE
				WHEN H.ToAcctID IN (26, 1494) THEN STo.Name
				WHEN H.ToAcctID IN (1452, 1559) THEN MTo.Name
				WHEN H.ToAcctID = 289 THEN CTo.Name
				ELSE NULL
			END,
		H.Remark,
		H.Amount
	FROM dbo.CustSupTransfer H
	LEFT JOIN dbo.AccountName FA ON H.FromAcctID = FA.ID
	LEFT JOIN dbo.AccountName TA ON H.ToAcctID = TA.ID
	LEFT JOIN dbo.Supplier SFrom
		ON H.FromAcctID IN (26, 1494) AND H.FromSourceID = SFrom.ID
	LEFT JOIN dbo.Manufacturer MFrom
		ON H.FromAcctID IN (1452, 1559) AND H.FromSourceID = MFrom.ID
	LEFT JOIN dbo.Customer CFrom
		ON H.FromAcctID = 289 AND H.FromSourceID = CFrom.ID
	LEFT JOIN dbo.Supplier STo
		ON H.ToAcctID IN (26, 1494) AND H.ToSourceID = STo.ID
	LEFT JOIN dbo.Manufacturer MTo
		ON H.ToAcctID IN (1452, 1559) AND H.ToSourceID = MTo.ID
	LEFT JOIN dbo.Customer CTo
		ON H.ToAcctID = 289 AND H.ToSourceID = CTo.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.Date BETWEEN @FDate AND @TDate
	  AND H.UserID = (CASE WHEN ISNULL(@UserID, 0) = 0 THEN H.UserID ELSE @UserID END)
	  AND (@AccountID = -1 OR H.FromAcctID = @AccountID OR H.ToAcctID = @AccountID)
	  AND (
			@CustomerID = -1
			OR (H.FromAcctID = 289 AND H.FromSourceID = @CustomerID)
			OR (H.ToAcctID = 289 AND H.ToSourceID = @CustomerID)
		  )
	  AND (
			@SupplierID = -1
			OR (H.FromAcctID IN (26, 1494) AND H.FromSourceID = @SupplierID)
			OR (H.ToAcctID IN (26, 1494) AND H.ToSourceID = @SupplierID)
		  )
);
GO

PRINT 'dbo.CustSupHistory updated (no GetCustSupName dependency).';
GO

-- Smoke test (should include ID 118 if still present)
SELECT ID, Date, AutoID, FromAcct, FromName, ToAcct, ToName, Amount
FROM dbo.CustSupHistory(0, '2026-08-01', '2026-09-14', -1, -1, -1)
ORDER BY ID;
GO
