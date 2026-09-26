/*======================================================================
  SB2 Bank Charges — run all SQL in order on the ERP database.
  Usage (sqlcmd):
    sqlcmd -S SERVER -d SB2 -E -i SB/Scripts/00_BankCharges_All.sql
======================================================================*/
SET NOCOUNT ON;
PRINT '=== 1) SaleHead_IsBankCharges ===';
:r SaleHead_IsBankCharges.sql
PRINT '=== 2) SaleHistory_AddCharges ===';
:r SaleHistory_AddCharges.sql
PRINT '=== 3) GeneralLedgerDetailReport_ExcludeAddAmount ===';
:r GeneralLedgerDetailReport_ExcludeAddAmount.sql
PRINT '=== 4) CustomerBalanceDetail_IncludeAddAmount ===';
:r CustomerBalanceDetail_IncludeAddAmount.sql
PRINT '=== 5) SaleHistory_FilterAccountPayment ===';
:r SaleHistory_FilterAccountPayment.sql
PRINT '=== OPTIONAL repair skipped by default ===';
-- :r SaleHead_TotalAmount_ExcludeAddAmount_Repair.sql
PRINT '=== Bank Charges SQL pack finished ===';
GO
