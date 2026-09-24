/*
  TitanBalance — consistency notes vs TitanBalanceDetail Opening fix
  (paste Script Date: 01/09/2026 10:15:50 AM)

  TitanBalance(@ToDate, @UserID) is an AS-OF closing report (no @FromDate).
  Loc section:
    @OpDate = MAX(StockOpeningHead.Date) WHERE Date <= @ToDate
    StockOpening on Date = @OpDate
    + movements Date Between @OpDate and @ToDate (Sale uses dbo.CastDate)

  Does the Detail @OpDate bug apply here?
  - NO for "@ToDate vs @FromDate": TitanBalance only has @ToDate, so
    @OpDate <= @ToDate is correct for closing balance as of ToDate.
  - Detail Opening must use @OpDate <= @PreDate so it equals
    "TitanBalance Loc as of PreDate" (carry-forward into the period).

  Remaining TitanBalance inconsistencies (optional follow-up, not required for Detail Opening bug):
  1) Sale uses dbo.CastDate(Date); Transfer/Purchase/Receive/RawIssue/Adjustment use raw Date.
     Prefer CastDate on all Loc movement branches for parity with Detail fix.
  2) StockOpening(Date=@OpDate) + movements Between @OpDate and @ToDate is inclusive
     on OpDate (same house pattern as CustomerBalanceDetail / GL Detail). If stock-take
     is end-of-day, OpDate activity can double-count — only change if business confirms.
  3) No location filter (intentional summary of all locs).

  No ALTER shipped here — TitanBalance @OpDate logic is fine for as-of ToDate.
  Deploy only docs/sql/TitanBalanceDetail_FixOpening.sql for the Opening (7) bug.
*/

PRINT 'TitanBalance: @OpDate <= @ToDate is intentional (as-of). See header comments.';
GO
