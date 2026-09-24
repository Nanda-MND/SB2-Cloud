/*
  GeneralLedgerDetailReport — Sale invoice bank/cash Debit WITHOUT AddAmount.

  App stores:
    SaleHead.TotalAmount = goods - discount + tax   (net into bank)
    SaleHead.AddAmount   = bank transfer fee        (Charges; not bank cash)

  Problem: older SaleHead.TotalAmount may still include AddAmount (e.g. 132357).
  Fix: all Sale → bank/cash Debits use:
    Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0))  -- e.g. 132000

  Applies to Opening + Detail period + Closing (SaleHead unions).
  Also run: SaleHead_TotalAmount_ExcludeAddAmount_Repair.sql (optional data cleanup).

  Account filter (multi-select from Reports form):
    @Account   = comma-separated AccountName.ID list (empty = all / use @AcctGroup)
    @AcctGroup = comma-separated AcctGroup.ID list (used when @Account empty)
  Requires: dbo.fn_AccountInFilter (see AccountFilter_Helper.sql)


  Run on: SB1 (Local; Cloud if GL report runs there).
*/

USE [SB1];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER Procedure [dbo].[GeneralLedgerDetailReport]
(
	@FromDate Datetime,
	@ToDate Datetime,
	@Account nvarchar(max) = '',
	@AcctGroup nvarchar(max) = '',
	@UserID int,
	@CurrencyID int
)As
Begin

		declare @OpDate Datetime, @PreDate Datetime
		select @OpDate = max(Date) From AccountOpeningHead Where isnull(Deleted,0)<>1  and Date <= @FromDate
		Set @OpDate = isnull(@OpDate,'2025-01-28')
		Set @PreDate = DATEADD(d,-1,@FromDate)
		delete From GeneralLedgerDetail Where UserID = @UserID

		insert into GeneralLedgerDetail(UserID, Date, DocumentID, Remark, LedgerName, AccountName, Debit, Credit, AccountHeader)
		Select @UserID, @FromDate, '   ', '',  LedgerName = A.Name, AccountName = 'Opening', Debit  = Sum(Debit) , Credit = 0,''
		From
		(	
				SELECT LedgerAccountID = D.AccountID, Debit = SUM((isnull(D.Debit,0)) - (isnull(D.Credit,0)))
				FROM dbo.AccountOpeningHead H JOIN AccountOpeningDetail D ON H.ID = d.RefID
				WHERE H.Date = @OpDate  And
				ISNULL(H.Deleted,0)<>1  AND
				dbo.fn_AccountInFilter(D.AccountID, @Account, @AcctGroup) = 1 
				GROUP BY D.AccountID
				Union All
				select LedgerID = H.AccountID, Debit = Sum((isnull(D.Debit,0)-isnull(D.Credit,0))* H.ExgRate)
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID 
				where isnull(Deleted,0)<>1 and CashbookTypeID =1
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				group by H.AccountID, H.CurrencyID
				Union all
				select LedgerID = DetailAccountID, Debit = sum(isnull(D.Credit,0)) - Sum(isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID
				where isnull(Deleted,0)<>1 and CashbookTypeID =1
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union all
				select LedgerID = DetailAccountID, Debit = Sum(isnull(D.Debit,0))- sum(isnull(Credit,0)) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID
				where isnull(Deleted,0)<>1 and CashbookTypeID =2
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID, H.CurrencyID
				Union all
				select LedgerID = H.AccountID, Debit = Sum(isnull(D.Debit,0)- isnull(Credit,0) - isnull(Discount,0) + isnull(Surplus,0)) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Customer C on D.SourceID = C.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 3
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				group by H.AccountID
				Union all
				select LedgerID = DetailAccountID, Debit = sum(isnull(Credit,0)) - Sum(isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Customer C on D.SourceID = C.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 3
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union All
				select LedgerID = H.AccountID, Debit = Sum((isnull(D.Debit,0)-isnull(D.Credit,0)) * H.ExgRate)
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				and H.AccountID in (SELECT ID FROM AccountName WHERE GroupID  <> 1012)
				group by H.AccountID, H.CurrencyID
				Union All
				select LedgerID = H.AccountID, Debit = Sum((isnull(D.Debit,0)-isnull(D.Credit,0)))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				and H.AccountID in (SELECT ID FROM AccountName WHERE GroupID  = 1012)
				group by H.AccountID, H.CurrencyID
				Union all
				select LedgerID = DetailAccountID, Debit = sum(isnull(Credit,0)) -  Sum(isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union All
				select LedgerID = H.AccountID, Debit = Sum(isnull(D.Debit,0))- sum(isnull(Credit,0)) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Manufacturer S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 5
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				group by H.AccountID
				Union all
				select LedgerID = DetailAccountID, Debit = sum(isnull(Credit,0)) -  Sum(isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Manufacturer S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 5
				and Date Between @OpDate and @PreDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union all
				select LedgerID = 113, Debit = sum(Discount)
				from SaleHead H 
				where isnull(H.Deleted,0)<>1 and dbo.CastDate(Date) Between @OpDate and @PreDate  and isnull(Discount,0)> 0
				/* Sale → bank/cash: net without AddAmount (Amount-Discount+Tax) */
				Union all
				select LedgerID = AccountID, Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0))
				from SaleHead H 
				where isnull(H.Deleted,0)<>1 and isnull(H.PaymenTID,0) not in (1,2,5)
				and dbo.CastDate(Date) Between @OpDate and @PreDate and dbo.CastDate(Date)<='2025-03-11'
				and dbo.fn_AccountInFilter(AccountID, @Account, @AcctGroup) = 1
				group by AccountID
				Union all
				select LedgerID = 288, Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0))
				from SaleHead H 
				where isnull(H.Deleted,0)<>1 
				and isnull(PaymentID,1)  = (Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)
				and dbo.CastDate(Date) Between @OpDate and @PreDate and dbo.CastDate(Date)>'2025-03-11'
				Union all
				select LedgerID = AccountID, Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0))
				from SaleHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  in (3,4)
				and dbo.CastDate(Date) Between @OpDate and @PreDate and dbo.CastDate(Date)>'2025-03-11'
				group by AccountID
				Union all
				select LedgerID = AccountID, Debit = -sum(TotalAmount)
				from SaleReturnHead H 
				where isnull(H.Deleted,0)<>1 and isnull(H.PaymenTID,0) not in (1,2,5)
				and dbo.CastDate(Date) Between @OpDate and @PreDate 
				and dbo.fn_AccountInFilter(AccountID, @Account, @AcctGroup) = 1
				group by AccountID
				Union all
				select LedgerID = 288, Debit = -sum(TotalAmount)
				from SaleReturnHead H 
				where isnull(H.Deleted,0)<>1 
				and isnull(PaymentID,1)  = (Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)
				and dbo.CastDate(Date) Between @OpDate and @PreDate 
				Union all
				select LedgerID = AccountID, Debit = -sum(TotalAmount)
				from SaleReturnHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  = 3
				and dbo.CastDate(Date) Between @OpDate and @PreDate 
				group by AccountID
				Union all
				select LedgerID = AccountID, Debit = sum(isnull(AdvAmount,0))
				from SaleOrderHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  not in (2,5)
				and dbo.CastDate(Date) Between @OpDate and @PreDate and dbo.CastDate(Date)>'2026-04-11'
				group by AccountID
				Union all
				select LedgerID = 1490, Debit = -sum(isnull(AdvAmount,0))
				from SaleOrderHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  not in (2,5)
				and dbo.CastDate(Date) Between @OpDate and @PreDate and dbo.CastDate(Date)>'2026-04-11'
				group by AccountID
		)opn Join AccountName A on LedgerAccountID = A.ID
		Where dbo.fn_AccountInFilter(LedgerAccountID, @Account, @AcctGroup) = 1
		Group by A.Name

		insert into GeneralLedgerDetail(UserID, Date, DocumentID, Remark, LedgerName, AccountName, Debit, Credit, AccountHeader, VrDate, Short)
		Select @UserID, Date, isnull(DocumentID,AutoID), Description, A.Name, AA.Name, Sum(Debit), Sum(Credit), '', VrDate, Tmp.Short 
		From
		(
		select Date, AutoID = '', DocumentID = '', LedgerID = H.AccountID, D.DetailAccountID, Description,  Debit = Sum(isnull(D.Debit,0) * H.ExgRate), Credit = sum(isnull(Credit,0) * H.ExgRate) , VrDate = Null, Short = ''
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID 
		where isnull(Deleted,0)<>1 and CashbookTypeID =1
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description
		Union all
		select Date, AutoID = '', DocumentID = '', LedgerID = D.DetailAccountID, H.AccountID , Description,  Debit =  Sum(isnull(D.Credit,0)), Credit = sum(isnull(Debit,0))  , VrDate = Null, Short = ''
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID
		where isnull(Deleted,0)<>1 and CashbookTypeID =1
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, H.CurrencyID
		Union all
		select Date, AutoID = '', DocumentID = '', LedgerID = D.DetailAccountID, AccountID = dbo.GetJournalAcctID(D.RefID, D.DetailAccountID) , Description,  Debit = Sum(isnull(D.Debit,0)), Credit = sum(isnull(D.Credit,0)) , VrDate = Null, Short = ''
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID
		where isnull(Deleted,0)<>1 and CashbookTypeID = 2
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  D.RefID, D.DetailAccountID, Description
		Union all
		select Date, AutoID = '', DocumentID = '', LedgerID = H.AccountID, D.DetailAccountID, Description = isnull(Description,'') + '  ' + C.Name ,  Debit = Sum(isnull(D.Debit,0) - isnull(Discount,0) + isnull(Surplus,0)), Credit = sum(isnull(Credit,0)) , VrDate = Null, Short = C.Short
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Customer C on D.SourceID = C.ID
		where isnull(H.Deleted,0)<>1 and CashbookTypeID = 3
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, C.Name, C.Short
		Union all
		select Date, AutoID = '', DocumentID = '', LedgerID = D.DetailAccountID, H.AccountID , Description = isnull(Description,'') + '  '  + C.Name,  Debit = Sum(isnull(D.Credit,0)), Credit = sum(isnull(Debit,0)) , VrDate = Null, Short = C.Short
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Customer C on D.SourceID = C.ID
		where isnull(H.Deleted,0)<>1 and CashbookTypeID = 3
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, C.Name, C.Short
		Union All
		select Date, AutoID = '', DocumentID = '', LedgerID = H.AccountID, D.DetailAccountID, Description = isnull(Description,'') + '  '  + S.Name,  Debit = sum(isnull(Debit,0) * H.ExgRate) , Credit =  Sum(isnull(D.Credit,0)* H.ExgRate)    , VrDate = Null, Short = S.Short
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
		where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		and H.AccountID in (SELECT ID FROM AccountName WHERE GroupID  <> 1012)
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, S.Name, H.CurrencyID, S.Short
		Union All
		select Date, AutoID = '', DocumentID = '', LedgerID = H.AccountID, D.DetailAccountID, Description = isnull(Description,'') + '  '  + S.Name,  Debit = sum(isnull(Debit,0) ) , Credit =  Sum(isnull(D.Credit,0))    , VrDate = Null, Short = S.Short
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
		where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		and H.AccountID in (SELECT ID FROM AccountName WHERE GroupID  = 1012)
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, S.Name, H.CurrencyID, S.Short
		Union all
		select Date, AutoID = '', DocumentID = '', LedgerID = D.DetailAccountID, H.AccountID , Description = isnull(Description,'') + '  '  + S.Name,  Debit = Sum(isnull(D.Credit,0)), Credit = sum(isnull(Debit,0)) , VrDate = Null, Short = S.Short
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
		where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, S.Name, S.Short
		Union All
		select Date, AutoID = '', DocumentID = '', LedgerID = H.AccountID, D.DetailAccountID, Description = isnull(Description,'') + '  '  + S.Name,  Debit = Sum(isnull(D.Debit,0)), Credit = sum(isnull(Credit,0)) , VrDate = Null, Short = S.Short
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Manufacturer S on D.SourceID = S.ID
		where isnull(H.Deleted,0)<>1 and CashbookTypeID = 5
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, S.Name, S.Short
		Union all
		select Date, AutoID = '', DocumentID = '', LedgerID = D.DetailAccountID, H.AccountID , Description = isnull(Description,'') + '  '  + S.Name,  Debit = Sum(isnull(D.Credit,0)), Credit = sum(isnull(Debit,0)) , VrDate = Null, Short = S.Short
		from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Manufacturer S on D.SourceID = S.ID
		where isnull(H.Deleted,0)<>1 and CashbookTypeID = 5
		and Date Between @FromDate and @ToDate
		and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID,  H.AccountID, D.DetailAccountID, Description, S.Name, S.Short
		Union all
		select Date = dbo.CastDate(Date), AutoID, Cast(DocumentID as nvarchar(15)), LedgerID = 113, AccountID = 112, Description = S.Name, Debit = sum(isnull(Discount,0)), Credit = 0, VrDate = dbo.CastDate(Date) , Short = S.Short
		from SaleHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 and dbo.CastDate(Date) Between @FromDate and @ToDate and isnull(Discount,0)> 0
		group by dbo.CastDate(Date), AutoID, DocumentID,  S.Name, S.Short
		Union all
		select Date = dbo.CastDate(Date), AutoID, Cast(DocumentID as nvarchar(15)), LedgerID = AccountID, AccountID =112, Description = S.Name,  Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0)), Credit = 0, VrDate = dbo.CastDate(Date) , Short = S.Short
		from SaleHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 and isnull(PaymentID,1) not in (1,2,5)
		and dbo.CastDate(Date) Between @FromDate and @ToDate and dbo.CastDate(Date)<='2025-03-11'
		and dbo.fn_AccountInFilter(AccountID, @Account, @AcctGroup) = 1
		group by dbo.CastDate(Date), AutoID, DocumentID, AccountID, S.Name, S.Short
		Union all
		select Date = dbo.CastDate(Date), AutoID, Cast(DocumentID as nvarchar(15)), LedgerID = AccountID, AccountID =112, Description = S.Name + '-'+ isnull(H.Remark,''),  Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0)), Credit = 0, VrDate = dbo.CastDate(Date) , Short = S.Short
		from SaleHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 and isnull(PaymentID,1) not in (1,2,5)
		and dbo.CastDate(Date) Between @FromDate and @ToDate and dbo.CastDate(Date)>'2025-03-11'
		and dbo.fn_AccountInFilter(AccountID, @Account, @AcctGroup) = 1
		group by dbo.CastDate(Date), AutoID, DocumentID, AccountID, S.Name, H.Remark, S.Short
		Union all
		select Date = dbo.CastDate(Date), AutoID = '', DocumentID = '', LedgerID = 288, AccountID =112, Description = 'Cash Sales',  Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0)), Credit = 0, VrDate = dbo.CastDate(Date) , Short = ''
		from SaleHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 
		and isnull(PaymentID,1)  = (Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)
		and dbo.CastDate(Date) Between @FromDate and @ToDate and dbo.CastDate(Date)>'2025-03-11'
		group by dbo.CastDate(Date)
		Union all
		select Date, AutoID, Cast(DocumentID as nvarchar(15)), LedgerID = AccountID, AccountID =114, Description = S.Name,  Debit = 0, Credit = sum(TotalAmount), VrDate = dbo.CastDate(Date) , Short = S.Short
		from SaleReturnHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 and isnull(PaymentID,1) not in (1,2,5)
		and dbo.CastDate(Date) Between @FromDate and @ToDate 
		and dbo.fn_AccountInFilter(AccountID, @Account, @AcctGroup) = 1
		group by Date, AutoID, DocumentID, AccountID, S.Name, S.Short
		Union all
		select Date = dbo.CastDate(Date), AutoID = '', DocumentID = '', LedgerID = 288, AccountID =114, Description = 'Sales Return',  Debit = 0, Credit = sum(TotalAmount), VrDate = dbo.CastDate(Date) , Short = ''
		from SaleReturnHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 
		and isnull(PaymentID,1)  = (Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)
		and dbo.CastDate(Date) Between @FromDate and @ToDate 
		group by dbo.CastDate(Date)
		Union all
		select Date = dbo.CastDate(Date), AutoID , DocumentID , LedgerID = 1490, AccountID , Description = S.Name,  Debit = 0, Credit = sum(isnull(AdvAmount,0)), VrDate = dbo.CastDate(Date) , Short = S.Short
		from SaleOrderHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 
		and isnull(PaymentID,1)  not in (2,5)
		and dbo.CastDate(Date) Between @FromDate and @ToDate  and dbo.CastDate(Date)>'2026-04-11'
		group by dbo.CastDate(Date), AccountID, AutoID, DocumentID, S.Short, S.Name
		Union all
		select Date = dbo.CastDate(Date), AutoID , DocumentID , LedgerID = AccountID, AccountID = 1490 , Description = S.Name,  Debit = sum(isnull(AdvAmount,0)), Credit = 0, VrDate = dbo.CastDate(Date) , Short = S.Short
		from SaleOrderHead H Join Customer S on H.CustomerID = S.ID
		where isnull(H.Deleted,0)<>1 
		and isnull(PaymentID,1)  not in (2,5)
		and dbo.CastDate(Date) Between @FromDate and @ToDate  and dbo.CastDate(Date)>'2026-04-11'
		group by dbo.CastDate(Date), AccountID, AutoID, DocumentID, s.Short, S.Name
		) tmp
		Join AccountName A on LedgerID = A.ID Join AccountName AA on DetailAccountID = AA.ID
		Where dbo.fn_AccountInFilter(LedgerID, @Account, @AcctGroup) = 1
		Group by Date, AutoID, DocumentID, Description, A.Name, AA.Name, VrDate, tmp.Short


		insert into GeneralLedgerDetail(UserID, Date, DocumentID, Remark, LedgerName, AccountName, Debit, Credit, AccountHeader)
		Select @UserID, @ToDate, 'zzzzz', '',  LedgerName = A.Name, AccountName = 'Closing', Debit  = 0 , Credit = Sum(Debit),''
		From
		(	
				SELECT LedgerAccountID = D.AccountID, Debit = Sum((isnull(D.Debit,0)-isnull(D.Credit,0)) ) 
				FROM dbo.AccountOpeningHead H JOIN AccountOpeningDetail D ON H.ID = d.RefID
				WHERE H.Date = @OpDate  And
				ISNULL(H.Deleted,0)<>1  AND
				dbo.fn_AccountInFilter(D.AccountID, @Account, @AcctGroup) = 1 
				GROUP BY D.AccountID, H.CurrencyID
				Union All
				select LedgerID = H.AccountID, Debit =  Sum((isnull(D.Debit,0)-isnull(D.Credit,0))  * H.Exgrate ) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID 
				where isnull(Deleted,0)<>1 and CashbookTypeID =1
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				group by H.AccountID, H.CurrencyID
				Union all
				select LedgerID = DetailAccountID, Debit = sum((isnull(Credit,0)) - isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID
				where isnull(Deleted,0)<>1 and CashbookTypeID =1
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union all
				select LedgerID = DetailAccountID, Debit = Sum(isnull(D.Debit,0) - isnull(Credit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID
				where isnull(Deleted,0)<>1 and CashbookTypeID = 2
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union all
				select LedgerID = H.AccountID, Debit = Sum(isnull(D.Debit,0)- isnull(Credit,0) - isnull(Discount,0) + isnull(Surplus,0)) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Customer C on D.SourceID = C.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 3
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				group by H.AccountID
				Union all
				select LedgerID = DetailAccountID, Debit = sum(isnull(Credit,0)) - Sum(isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Customer C on D.SourceID = C.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 3
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union All
				select LedgerID = H.AccountID, Debit = Sum((isnull(D.Debit,0)-isnull(D.Credit,0))* H.ExgRate) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				and H.AccountID in (SELECT ID FROM AccountName WHERE GroupID  <> 1012)
				group by H.AccountID, H.CurrencyID
				Union All
				select LedgerID = H.AccountID, Debit = Sum((isnull(D.Debit,0)-isnull(D.Credit,0))) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				and H.AccountID in (SELECT ID FROM AccountName WHERE GroupID  = 1012)
				group by H.AccountID, H.CurrencyID
				Union all
				select LedgerID = DetailAccountID, Debit = sum(isnull(Credit,0)) -  Sum(isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Supplier S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 4
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union All
				select LedgerID = H.AccountID, Debit = Sum(isnull(D.Debit,0))- sum(isnull(Credit,0)) 
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Manufacturer S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 5
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
				group by H.AccountID
				Union all
				select LedgerID = DetailAccountID, Debit = sum(isnull(Credit,0)) -  Sum(isnull(D.Debit,0))
				from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join Manufacturer S on D.SourceID = S.ID
				where isnull(H.Deleted,0)<>1 and CashbookTypeID = 5
				and Date Between @OpDate and @ToDate
				and dbo.fn_AccountInFilter(DetailAccountID, @Account, @AcctGroup) = 1
				group by DetailAccountID
				Union all
				select LedgerID = 113, Debit = sum(isnull(Discount,0))
				from SaleHead H 
				where isnull(H.Deleted,0)<>1 and dbo.CastDate(Date) Between @OpDate and @ToDate and isnull(Discount,0)> 0
				Union all
				select LedgerID = AccountID, Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0))
				from SaleHead H 
				where isnull(H.Deleted,0)<>1  and isnull(PaymentID,1) not in (1,2,5)
				and dbo.CastDate(Date) Between @OpDate and @ToDate and dbo.CastDate(Date)<='2025-03-11'
				and dbo.fn_AccountInFilter(AccountID, @Account, @AcctGroup) = 1
				group by AccountID
				Union all
				select LedgerID = 288, Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0))
				from SaleHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  = (Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)
				and dbo.CastDate(Date) Between @OpDate and @ToDate and dbo.CastDate(Date)>'2025-03-11'
				Union all
				select LedgerID = AccountID, Debit = sum(isnull(Amount,0) - isnull(Discount,0) + isnull(TaxAmount,0))
				from SaleHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  in (3,4)
				and dbo.CastDate(Date) Between @OpDate and @ToDate and dbo.CastDate(Date)>'2025-03-11'
				group by AccountID
				Union all
				select LedgerID = AccountID, Debit = -sum(TotalAmount)
				from SaleReturnHead H 
				where isnull(H.Deleted,0)<>1  and isnull(PaymentID,1) not in (1,2,5)
				and dbo.CastDate(Date) Between @OpDate and @ToDate 
				and dbo.fn_AccountInFilter(AccountID, @Account, @AcctGroup) = 1
				group by AccountID
				Union all
				select LedgerID = 288, Debit = -sum(TotalAmount)
				from SaleReturnHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  = (Case When dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1 Then 1 Else 0 End)
				and dbo.CastDate(Date) Between @OpDate and @ToDate 
				Union all
				select LedgerID = AccountID, Debit = -sum(TotalAmount)
				from SaleReturnHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  = 3
				and dbo.CastDate(Date) Between @OpDate and @ToDate 
				group by AccountID
				Union all
				select LedgerID = AccountID, Debit = sum(isnull(AdvAmount,0))
				from SaleOrderHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  not in (2,5)
				and dbo.CastDate(Date) Between @OpDate and @ToDate  and dbo.CastDate(Date)>'2026-04-11'
				group by AccountID
				Union all
				select LedgerID = 1490, Debit = -sum(isnull(AdvAmount,0))
				from SaleOrderHead H 
				where isnull(H.Deleted,0)<>1  
				and isnull(PaymentID,1)  not in (2,5)
				and dbo.CastDate(Date) Between @OpDate and @ToDate  and dbo.CastDate(Date)>'2026-04-11'
				group by AccountID
		)opn Join AccountName A on LedgerAccountID = A.ID
		Where dbo.fn_AccountInFilter(LedgerAccountID, @Account, @AcctGroup) = 1
		Group by A.Name


End
GO

PRINT 'GeneralLedgerDetailReport: Sale bank Debit = Amount-Discount+Tax (excludes AddAmount).';
GO
