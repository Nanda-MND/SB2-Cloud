/*
  TitanBalanceDetail — fix Opening balance (e.g. showed (7) instead of 6,994).

  Bugs in prior SP (SSMS paste 01-09-2026):
  1) @OpDate = MAX(StockOpeningHead.Date) WHERE Date <= @ToDate
     When a stock-take exists on/after FromDate (common when From=To),
     @OpDate > @PreDate → movement window empty → Opening = only that voucher
     (wrong / partial → e.g. (7) instead of carry-forward 6,994).
     Fix: @OpDate = latest opening with Date <= @PreDate (day before FromDate).
     Opening = balance as of @PreDate (same idea as TitanBalance Loc as-of PreDate).

  2) Sale (and other) opening/period filters did not use dbo.CastDate like TitanBalance Loc.
     Fix: use dbo.CastDate(Date) on movement date filters.

  3) Adjustment opening branch missing Join #Customer and Group by LocationID only
     (other branches Group by LocationID, CodeID). Fixed both.

  4) Leftover debug: SELECT * FROM #Customer — removed.

  5) Period Transfer IN (ToLocID) posted Credit instead of Debit — stock in must Increase.
     Transfer OUT stays Credit.

  6) All-locations mode used TypeID = 2 only, so TypeID=1 sites (60-ATT…)
     disappeared when no location filter. Fixed: all non-deleted locations.

  Deploy on SB1, then re-test Titan Balance Detail:
  - with location filter 60-ATT (still OK)
  - with all locations (60-ATT must appear)
*/

USE [SB1]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[TitanBalanceDetail]
(
	@FromDate Datetime,
	@ToDate Datetime,
	@Location nvarchar(1024) = null,
	@UserID int
)As
Begin

		declare @OpDate Datetime, @PreDate Datetime
		Set @PreDate = DATEADD(d,-1,@FromDate)

		/* Opening stock-take must be on/before day before FromDate — NOT <= @ToDate */
		Select @OpDate = max(Date) from StockOpeningHead
		Where isnull(Deleted,0)<>1 and Date <= @PreDate

		if @OpDate is null
			set @OpDate = '2025-01-28'

		Declare @Code nvarchar(max)
		Create Table #Customer (c_id int)
		if len(isnull(@Location,'')) > 0
			Set @Code = 'insert into #Customer select ID From Location Where ID in ('+ @Location+') and isnull(Deleted,0)<>1'
		else
			/* All locations: do NOT restrict TypeID=2 — that hid TypeID=1 sites like 60-ATT */
			Set @Code = 'insert into #Customer select ID From Location Where isnull(Deleted,0)<>1'

		exec (@Code)

		delete From GeneralLedgerDetail Where UserID = @UserID

		/* Opening = StockOpening(@OpDate) + movements @OpDate..@PreDate (inclusive, same as TitanBalance Loc window) */
		insert into GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
		Select @UserID, @FromDate, DocumentID = '   ',  LedgerName = C.Name, AccountName = 'Opening', AccountHeader = '', Amount = Sum(TotalWeight) From
		(
		Select LocationID,  TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) from StockOpeningHead H Join StockOpeningDetail D on H.ID = D.RefID Join #Customer C on H.LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and Date = @OpDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by LocationID, CodeID
		Union All
		Select LocationID,  TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID Join #Customer C on H.LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @OpDate and @PreDate and isnull(StockReceived,0) = 1
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by LocationID, CodeID
		Union All
		select ToLocID, TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) from TransferHead H Join TransferDetail D on H.ID = D.RefID Join #Customer C on H.ToLocID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @OpDate and @PreDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group By ToLocID, CodeID
		Union All
		select FromLocID, TotalWeight = -Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) from TransferHead H Join TransferDetail D on H.ID = D.RefID Join #Customer C on H.FromLocID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @OpDate and @PreDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group By FromLocID, CodeID
		Union All
		select LocationID, TotalWeight = -Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) from SaleHead H Join SaleDetail D on H.ID = D.RefID Join #Customer C on H.LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @OpDate and @PreDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group By LocationID, CodeID
		Union All
		Select LocationID,  TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) from StockReceiveHead H Join StockReceiveDetail D on H.ID = D.RefID Join #Customer C on H.LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @OpDate and @PreDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by LocationID , CodeID
		Union All
		Select LocationID, TotalWeight = -Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) from RawIssueHead H Join RawIssueDetail D on H.ID = D.RefID Join #Customer C on H.LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<>1 and dbo.CastDate(Date) Between @OpDate and @PreDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by LocationID, CodeID
		Union All
		Select LocationID,  TotalWeight = Sum(Case When AT.Type = '+' Then dbo.GetMinQty(CodeID, UnitID, Qty) Else -dbo.GetMinQty(CodeID, UnitID, Qty) End)
		from AdjustmentHead H Join AdjustmentDetail D on H.ID = D.RefID Join AdjustType AT on AdjustTypeID = AT.ID
		Join #Customer C on H.LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @OpDate and @PreDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by LocationID, CodeID
		)opn
		Join Location C on LocationID = C.ID
		Group by C.Name

		insert into GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Debit, Credit, Remark)
		Select @UserID, Date, isnull(DocumentID,AutoID), Location = L.Name, '',  Pkg = dbo.GetQtyinUnitRelation(CodeID, Sum(dbo.GetMinQty(CodeID, UnitID, Qty))),  TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) , 0, H.Remark from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID
		Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on D.UnitID = U.ID Join #Customer C on LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @FromDate and @ToDate and isnull(StockReceived,0) = 1
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by Date, AutoID, DocumentID,  L.Name, CodeID, H.Remark
		Union All
		Select @UserID, Date, isnull(DocumentID,AutoID), Location = L.Name, '',  Pkg = dbo.GetQtyinUnitRelation(CodeID, Sum(dbo.GetMinQty(CodeID, UnitID, Qty))),  TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) , 0, H.Remark from StockReceiveHead H Join StockReceiveDetail D on H.ID = D.RefID
		Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on D.UnitID = U.ID Join #Customer C on LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @FromDate and @ToDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by Date, AutoID, DocumentID,  L.Name, CodeID, H.Remark
		Union All
		Select @UserID, Date, isnull(D.Remark,''), Location = L.Name, M.Name,  Pkg = dbo.GetQtyinUnitRelation(CodeID, Sum(dbo.GetMinQty(CodeID, UnitID, Qty))) ,  0, TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)), H.Remark  from RawIssueHead H Join RawIssueDetail D on H.ID = D.RefID
		Join Location L on H.LocationID = L.ID Join Manufacturer M on ManufacturerID = M.ID Join Stock S on D.CodeID = S.ID Join Unit U on D.UnitID = U.ID Join #Customer C on LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @FromDate and @ToDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by Date, AutoID, DocumentID, M.Name, L.Name, CodeID, D.Remark, H.Remark
		Union All
		/* Transfer IN → Debit (increase) */
		select @UserID, Date, isnull(DocumentID,AutoID), Location = L.Name, LL.Name, Pkg = dbo.GetQtyinUnitRelation(CodeID, Sum(dbo.GetMinQty(CodeID, UnitID, Qty))) ,  TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)) ,  0, H.Remark from TransferHead H Join TransferDetail D on H.ID = D.RefID Join #Customer C on H.ToLocID = C.c_id
		Join Location L on H.ToLocID = L.ID Join Location LL on H.FromLocID = LL.ID
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @FromDate and @ToDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group By Date, AutoID, DocumentID, L.Name, LL.Name, CodeID, H.Remark
		Union All
		/* Transfer OUT → Credit (decrease) */
		select @UserID, Date, isnull(DocumentID,AutoID), Location = L.Name, LL.Name, Pkg = dbo.GetQtyinUnitRelation(CodeID, Sum(dbo.GetMinQty(CodeID, UnitID, Qty))) ,  0,  TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)), H.Remark from TransferHead H Join TransferDetail D on H.ID = D.RefID Join #Customer C on H.FromLocID = C.c_id
		Join Location L on H.FromLocID = L.ID Join Location LL on H.ToLocID = LL.ID
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @FromDate and @ToDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group By Date, AutoID, DocumentID, L.Name, LL.Name, CodeID, H.Remark
		Union All
		Select @UserID, Date, isnull(Cast(DocumentID as nvarchar), AutoID), Location = L.Name, '',  Pkg = dbo.GetQtyinUnitRelation(CodeID, Sum(dbo.GetMinQty(CodeID, UnitID, Qty))),  0 , TotalWeight = Sum(dbo.GetMinQty(CodeID, UnitID, Qty)), H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID
		Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on D.UnitID = U.ID Join #Customer C on LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @FromDate and @ToDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by Date, AutoID, DocumentID,  L.Name, CodeID, H.Remark
		Union All
		/* Adjustment in period — was missing (e.g. G260900001 Decrease 110 lb on 01-09-2026) */
		Select @UserID, Date, isnull(Cast(DocumentID as nvarchar), AutoID), Location = L.Name, AT.Name,
			Pkg = dbo.GetQtyinUnitRelation(CodeID, Sum(dbo.GetMinQty(CodeID, UnitID, Qty))),
			Debit  = Sum(Case When AT.Type = '+' Then dbo.GetMinQty(CodeID, UnitID, Qty) Else 0 End),
			Credit = Sum(Case When AT.Type = '+' Then 0 Else dbo.GetMinQty(CodeID, UnitID, Qty) End),
			H.Remark
		from AdjustmentHead H
		Join AdjustmentDetail D on H.ID = D.RefID
		Join AdjustType AT on D.AdjustTypeID = AT.ID
		Join Location L on H.LocationID = L.ID
		Join #Customer C on H.LocationID = C.c_id
		Where ISNULL(H.Deleted,0)<> 1 and dbo.CastDate(Date) Between @FromDate and @ToDate
		and CodeID in (Select ID From Stock Where GroupID = 25)
		Group by Date, AutoID, DocumentID, L.Name, AT.Name, AT.Type, CodeID, H.Remark

		Drop Table #Customer
End
GO

PRINT 'TitanBalanceDetail: Opening fixed; period includes Adjustment Increase/Decrease.';
GO
