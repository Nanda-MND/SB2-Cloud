/*
  CustomerBalanceDetail — credit receivable + bank-fee clear.

  App saves:
    SaleHead.TotalAmount = Amount - Discount + TaxAmount   (goods net, no fee)
    SaleHead.AddAmount   = bank transfer fee
    UI / invoice စုစုပေါင်း = TotalAmount + AddAmount

  1) Sales / Sales Return receivable (PaymentID 2,5):
       ISNULL(TotalAmount,0) + ISNULL(AddAmount,0) - ISNULL(PaidAmount,0)

  2) After money is in (Sale.PaidAmount and/or customer IE/transfer receipts
     cover that sale's remaining goods FIFO), Credit AddAmount under
     AccountName = N'ဘဏ်ဝန်ဆောင်ခ' so balance returns to 0.

  Example (27-08-2026 ok(ညောင်တုန်း)):
    Sales Debit 396,893 (= goods 396,000 + fee 893)
    IE Credit   396,000
    ဘဏ်ဝန်ဆောင်ခ Credit 893  → balance 0

  Deploy after (if old rows still bake fee into TotalAmount):
    docs/sql/SaleHead_TotalAmount_ExcludeAddAmount_Repair.sql

  Also update dbo.GetCustomerBalance the same way if it uses TotalAmount only.
*/

ALTER Procedure [dbo].[CustomerBalanceDetail]
(
	@FromDate Datetime,
	@ToDate Datetime,
	@Division nvarchar(1024) = null ,
	@Township nvarchar(1024) = null,
	@Customer nvarchar(1024) = null,
	@UserID int
)As
Begin

		declare @OpDate Datetime, @PreDate Datetime
		Select @OpDate = MAX(Date) From CustomerOpeningHead Where isnull(Deleted,0)<>1 and Date <= @FromDate
		if @OpDate is null
			Set @OpDate = '2025-01-28'
		Set @PreDate = DATEADD(d,-1,@FromDate)
		delete From GeneralLedgerDetail Where UserID = @UserID

		Declare @Code nvarchar(max)
		Create Table #Customer (c_id int)
		if len(@Customer) > 0
			Set @Code = 'insert into #Customer select ID From Customer Where ID in ('+ @Customer+')'
		else if Len(@Township)>0
			Set @Code = 'insert into #Customer select ID From Customer Where TownshipID in ('+ @Township+')'
		else if Len(@Division)>0
			Set @Code = 'insert into #Customer select ID From Customer C Join Township T on C.TownshipID = T.ID Where DivisionId in ('+ @Division+')'
		else
			Set @Code = 'insert into #Customer select ID From Customer Where isnull(Deleted,0)<>1'

		exec (@Code)

		/* Receipts that clear goods — cut off at @AsOf inside the inline uses below. */
		Create Table #CustReceiptAsOf (CustomerID int not null, AsOf datetime not null, Amt money not null,
			Primary Key (CustomerID, AsOf))

		;With Cuts as
		(
			Select AsOf = @PreDate
			Union All
			Select AsOf = @ToDate
		),
		Raw as
		(
			Select CustomerID = D.SourceID, C.AsOf, Amt = Sum(isnull(D.Debit,0) - isnull(D.Credit,0))
			From Cuts C
			Join IncomeExpenseHead H on dbo.CastDate(H.Date) between @OpDate and C.AsOf
			Join IncomeExpenseDetail D on H.ID = D.RefID
			Join #Customer X on D.SourceID = X.c_id
			Where ISNULL(H.Deleted,0)<>1 and CashbookTypeID = 3
			Group by D.SourceID, C.AsOf
			Union All
			Select H.ToSourceID, C.AsOf, Sum(Amount)
			From Cuts C
			Join CustSupTransfer H on dbo.CastDate(H.Date) between @OpDate and C.AsOf
			Join #Customer X on H.ToSourceID = X.c_id
			Where ISNULL(H.Deleted,0)<>1 and ToAcctID = 289 and FromAcctID in (26,1452)
			Group by H.ToSourceID, C.AsOf
			Union All
			Select H.FromSourceID, C.AsOf, Sum(Amount)
			From Cuts C
			Join CustSupTransfer H on dbo.CastDate(H.Date) between @OpDate and C.AsOf
			Join #Customer X on H.FromSourceID = X.c_id
			Where ISNULL(H.Deleted,0)<>1 and FromAcctID = 289 and ToAcctID in (26,1452)
			Group by H.FromSourceID, C.AsOf
			Union All
			Select H.FromSourceID, C.AsOf, Sum(Amount)
			From Cuts C
			Join CustSupTransfer H on dbo.CastDate(H.Date) between @OpDate and C.AsOf
			Join #Customer X on H.FromSourceID = X.c_id
			Where ISNULL(H.Deleted,0)<>1 and FromAcctID = 289 and ToAcctID not in (26,1452)
			Group by H.FromSourceID, C.AsOf
		)
		Insert into #CustReceiptAsOf (CustomerID, AsOf, Amt)
		Select CustomerID, AsOf, Sum(Amt)
		From Raw
		Group by CustomerID, AsOf

		/*
		  Credit-sale fees to clear once receipts cover remaining goods FIFO.
		  Remaining goods = TotalAmount - PaidAmount.
		  ClearedByPre  → already netted into Opening
		  ClearedInPeriod → show Credit row AccountName = N'ဘဏ်ဝန်ဆောင်ခ'
		*/
		Create Table #BankFeeClear
		(
			SaleID int not null,
			CustomerID int not null,
			SaleDate datetime not null,
			DocumentID nvarchar(50) null,
			AutoID nvarchar(50) null,
			AddAmount money not null,
			ClearedByPre bit not null,
			ClearedInPeriod bit not null
		)

		;With SaleGoods as
		(
			Select
				H.ID,
				H.CustomerID,
				SaleDate = H.Date,
				H.DocumentID,
				H.AutoID,
				AddAmount = isnull(H.AddAmount,0),
				RemainGoods = isnull(H.TotalAmount,0) - isnull(H.PaidAmount,0)
			From SaleHead H
			Join #Customer C on H.CustomerID = C.c_id
			Where ISNULL(H.Deleted,0)<>1
			  and H.PaymentID in (2,5)
			  and isnull(H.AddAmount,0) <> 0
			  and dbo.CastDate(H.Date) between @OpDate and @ToDate
		),
		SaleRun as
		(
			Select
				S.*,
				RunRemain = Sum(Case When RemainGoods > 0 Then RemainGoods Else 0 End)
					Over (Partition by CustomerID Order by SaleDate, ID Rows Unbounded Preceding)
			From SaleGoods S
		)
		Insert into #BankFeeClear (SaleID, CustomerID, SaleDate, DocumentID, AutoID, AddAmount, ClearedByPre, ClearedInPeriod)
		Select
			R.ID,
			R.CustomerID,
			R.SaleDate,
			R.DocumentID,
			R.AutoID,
			R.AddAmount,
			ClearedByPre = Case
				When dbo.CastDate(R.SaleDate) > @PreDate Then 0
				When R.RemainGoods <= 0 Then 1
				When isnull(RPre.Amt,0) >= R.RunRemain Then 1
				Else 0 End,
			ClearedInPeriod = Case
				When R.RemainGoods <= 0
					And dbo.CastDate(R.SaleDate) between @FromDate and @ToDate Then 1
				When isnull(RTo.Amt,0) >= R.RunRemain
					And Not (
						dbo.CastDate(R.SaleDate) <= @PreDate
						And (R.RemainGoods <= 0 Or isnull(RPre.Amt,0) >= R.RunRemain)
					) Then 1
				Else 0 End
		From SaleRun R
		Left Join #CustReceiptAsOf RPre on RPre.CustomerID = R.CustomerID and RPre.AsOf = @PreDate
		Left Join #CustReceiptAsOf RTo  on RTo.CustomerID  = R.CustomerID and RTo.AsOf  = @ToDate
		Where R.RemainGoods <= 0
		   or isnull(RTo.Amt,0) >= R.RunRemain
		   or (dbo.CastDate(R.SaleDate) <= @PreDate and isnull(RPre.Amt,0) >= R.RunRemain)

		insert into GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
		Select @UserID, @FromDate, DocumentID = '   ',  LedgerName = C.Name, AccountName = 'Opening', AccountHeader = '', Amount = Sum(Amount) From
		(
		Select CustomerID, Amount = Sum(D.Amount) From CustomerOpeningHead H Join CustomerOpeningDetail D on H.ID = D.RefID Join #Customer C on D.CustomerID = C.c_id 
		Where ISNULL(Deleted,0)<>1 
		And dbo.CastDate(Date) = @OpDate and isnull(isOpening,0) = 1
		Group by CustomerID
		Union All
		Select CustomerID, Amount = -Sum(D.Amount) From CustomerOpeningHead H Join CustomerOpeningDetail D on H.ID = D.RefID Join #Customer C on D.CustomerID = C.c_id 
		Where ISNULL(Deleted,0)<>1 
		And dbo.CastDate(Date) = @OpDate and isnull(isOpening,0) = 0
		Group by CustomerID
		Union All
		Select CustomerID, Amount = Sum(isnull(TotalAmount,0) + isnull(AddAmount,0) - isnull(PaidAmount,0) )  From SaleHead H Join #Customer C on H.CustomerID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and PaymentID in (2,5)
		and dbo.CastDate(Date) between @OpDate and @PreDate
		Group by CustomerID
		Union All
		/* Opening: bank fee already cleared by money-in on/before PreDate */
		Select CustomerID, Amount = -Sum(AddAmount)
		From #BankFeeClear
		Where ClearedByPre = 1
		Group by CustomerID
		Union All
		Select CustomerID, Amount = -Sum(isnull(TotalAmount,0) + isnull(AddAmount,0) - isnull(PaidAmount,0)) From SaleReturnHead H Join #Customer C on H.CustomerID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and PaymentID in (2,5)
		and dbo.CastDate(Date) between @OpDate and @PreDate
		Group by CustomerID
		Union All
		Select CustomerID, Amount = -Sum(isnull(AdvAmount,0)) From SaleOrderHead H Join #Customer C on H.CustomerID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and PaymentID not in (2,5)
		and dbo.CastDate(Date) between @OpDate and @PreDate and dbo.CastDate(Date)>'2026-04-11'
		Group by CustomerID
		Union All
		Select D.SourceID,Amount = - Sum(isnull(D.Debit,0) - isnull(D.Credit,0)) From IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join #Customer C on D.SourceID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and CashbookTypeID = 3 
		and Date between @OpDate and @PreDate
		Group by SourceID
		Union All
		Select H.ToSourceID, Amount = -Sum(Amount) From CustSupTransfer H Join #Customer C on H.ToSourceID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and ToAcctID = 289 and FromAcctID in (26,1452)
		and Date between @OpDate and @PreDate
		Group by ToSourceID
		Union All
		Select H.FromSourceID, Amount = -Sum(Amount) From CustSupTransfer H Join #Customer C on H.FromSourceID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and FromAcctID = 289  and ToAcctID in (26,1452)
		and Date between @OpDate and @PreDate
		Group by FromSourceID
		Union All
		Select H.ToSourceID, Amount = Sum(Amount) From CustSupTransfer H Join #Customer C on H.ToSourceID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and ToAcctID = 289 and FromAcctID not in (26,1452)
		and Date between @OpDate and @PreDate
		Group by ToSourceID
		Union All
		Select H.FromSourceID, Amount = -Sum(Amount) From CustSupTransfer H Join #Customer C on H.FromSourceID = C.c_id 
		Where ISNULL(Deleted,0)<>1 and FromAcctID = 289  and ToAcctID not in (26,1452)
		and Date between @OpDate and @PreDate
		Group by FromSourceID
		)opn 
		Join Customer C on CustomerID = C.ID
		Group by C.Name

		insert into GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Debit, Credit)
		Select @UserID, H.Date, isnull(Cast(DocumentID as nvarchar), AutoID), CC.Name, 'Sales', '', Debit = Sum(isnull(TotalAmount,0) + isnull(AddAmount,0) - isnull(PaidAmount,0) ) , Credit = 0 From SaleHead H  Join #Customer C on H.CustomerID = C.c_id 
		Join Customer CC on CustomerID = CC.ID
		Where ISNULL(H.Deleted,0)<>1 and PaymentID in (2,5)
		and dbo.CastDate(Date) between @FromDate and @ToDate
		Group by H.Date, AutoID,DocumentID, CC.Name
		Union All
		Select @UserID, H.Date, isnull(Cast(DocumentID as nvarchar), AutoID), CC.Name, 'Sales Return', '', Debit = 0, Credit = Sum(isnull(TotalAmount,0) + isnull(AddAmount,0) - isnull(PaidAmount,0))  From SaleReturnHead H  Join #Customer C on H.CustomerID = C.c_id 
		Join Customer CC on CustomerID = CC.ID 
		Where ISNULL(H.Deleted,0)<>1 and PaymentID in (2,5)
		and dbo.CastDate(Date) between @FromDate and @ToDate
		Group by H.Date, AutoID,DocumentID, CC.Name
		Union All
		/* Money-in cleared bank fee — ဘဏ်ဝန်ဆောင်ခ (sale in period, or opening sale paid this period) */
		Select @UserID, F.SaleDate, isnull(Cast(F.DocumentID as nvarchar), F.AutoID), CC.Name, N'ဘဏ်ဝန်ဆောင်ခ', '', Debit = 0, Credit = Sum(F.AddAmount)
		From #BankFeeClear F
		Join Customer CC on F.CustomerID = CC.ID
		Where F.ClearedInPeriod = 1
		Group by F.SaleDate, F.AutoID, F.DocumentID, CC.Name
		Union All
		Select @UserID, H.Date, isnull(Cast(DocumentID as nvarchar), AutoID), CC.Name, 'Sales Order', A.Name, Debit = 0, Credit = Sum(isnull(AdvAmount,0))  From SaleOrderHead H  Join #Customer C on H.CustomerID = C.c_id 
		Join Customer CC on CustomerID = CC.ID Join AccountName A on H.AccountID = A.ID
		Where ISNULL(H.Deleted,0)<>1 and PaymentID not in (2,5)
		and dbo.CastDate(Date) between @FromDate and @ToDate and dbo.CastDate(Date)>'2026-04-11'
		Group by H.Date, AutoID,DocumentID, CC.Name, A.Name
		Union All
		Select @UserID, H.Date, isnull(DocumentID, AutoID), CC.Name, 'Income/Expense', A.Name, Debit = 0, Credit = Sum(isnull(D.Debit,0) - isnull(D.Credit,0)) From IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join #Customer C on D.SourceID = C.c_id 
		Join Customer CC on SourceID = CC.ID Join AccountName A on H.AccountID = A.ID
		Where ISNULL(H.Deleted,0)<>1 and CashbookTypeID = 3 
		and Date between @FromDate and @ToDate
		Group by H.Date, AutoID, DocumentID, CC.Name, A.Name, D.Description
		Union All
		Select @UserID, H.Date, isnull(DocumentID, AutoID), CC.Name, 'Acct Transfer', A.Name, Debit = 0, Credit = Sum(Amount) From CustSupTransfer H Join #Customer C on H.ToSourceID = C.c_id 
		Join Customer CC on ToSourceID = CC.ID Join AccountName A on H.ToAcctID = A.ID
		Where ISNULL(H.Deleted,0)<>1 and ToAcctID = 289 and FromAcctID in (26,1452)
		and Date between @FromDate and @ToDate
		Group by H.Date, AutoID, DocumentID, CC.Name, A.Name
		Union All
		Select @UserID, H.Date, isnull(DocumentID, AutoID), CC.Name, 'Acct Transfer', A.Name, Debit = 0, Credit = Sum(Amount) From CustSupTransfer H Join #Customer C on H.FromSourceID = C.c_id 
		Join Customer CC on FromSourceID = CC.ID Join AccountName A on H.FromAcctID = A.ID
		Where ISNULL(H.Deleted,0)<>1 and FromAcctID = 289 and ToAcctID in (26,1452)
		and Date between @FromDate and @ToDate
		Group by H.Date, AutoID, DocumentID, CC.Name, A.Name
		Union All
		Select @UserID, H.Date, isnull(DocumentID, AutoID), CC.Name, 'Acct Transfer', A.Name, Debit = Sum(Amount), Credit = 0 From CustSupTransfer H Join #Customer C on H.ToSourceID = C.c_id 
		Join Customer CC on ToSourceID = CC.ID Join AccountName A on H.ToAcctID = A.ID
		Where ISNULL(H.Deleted,0)<>1 and ToAcctID = 289 and FromAcctID not in (26,1452)
		and Date between @FromDate and @ToDate
		Group by H.Date, AutoID, DocumentID, CC.Name, A.Name
		Union All
		Select @UserID, H.Date, isnull(DocumentID, AutoID), CC.Name, 'Acct Transfer', A.Name, Debit = 0, Credit = Sum(Amount) From CustSupTransfer H Join #Customer C on H.FromSourceID = C.c_id 
		Join Customer CC on FromSourceID = CC.ID Join AccountName A on H.FromAcctID = A.ID
		Where ISNULL(H.Deleted,0)<>1 and FromAcctID = 289 and ToAcctID not in (26,1452)
		and Date between @FromDate and @ToDate
		Group by H.Date, AutoID, DocumentID, CC.Name, A.Name

		Drop Table #BankFeeClear
		Drop Table #CustReceiptAsOf
		Drop Table #Customer
End
GO

PRINT 'CustomerBalanceDetail: Sales = TotalAmount+AddAmount; money-in clears AddAmount as ဘဏ်ဝန်ဆောင်ခ.';
GO
