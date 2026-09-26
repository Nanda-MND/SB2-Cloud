#Requires -Version 5.1
# Suite A: Full txn NEW/EDIT/DELETE + conflict matrix (sole /once owner)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$evDir = "D:\Dev\SB2-Cloud-Runtime\e2e_evidence\all_txn_20260926_225738"
New-Item -ItemType Directory -Force -Path $evDir | Out-Null
$localPwd = $env:SB2_DEV_LOCAL_SQL_PASSWORD
$cloudPwd = $env:SB2_TEST_CLOUD_SQL_PASSWORD
if ([string]::IsNullOrWhiteSpace($localPwd)) { throw 'SB2_DEV_LOCAL_SQL_PASSWORD missing' }
if ([string]::IsNullOrWhiteSpace($cloudPwd)) { throw 'SB2_TEST_CLOUD_SQL_PASSWORD missing' }
$marker = "E2E_ALLTXN_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$results = [ordered]@{}
$skips = [ordered]@{}
$suiteName = "SuiteA_AllTxn_Matrix"

function Invoke-Sql([string]$server,[string]$db,[string]$user,[string]$pwd,[string]$q,[string]$label) {
  $tmp = Join-Path $env:TEMP ("sb2q_" + [guid]::NewGuid().ToString('N') + ".sql")
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($tmp, $q, $utf8)
  $attempts = 0
  while ($true) {
    $attempts++
    $out = & sqlcmd -S $server -d $db -U $user -P $pwd -b -s "`t" -l 60 -i $tmp 2>&1
    $exit = $LASTEXITCODE
    $text = ($out | Out-String)
    if ($exit -eq 0) {
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
      if ($label) { $text | Set-Content (Join-Path $evDir "$label.txt") -Encoding UTF8 }
      return $text
    }
    if ($attempts -ge 5 -or ($text -notmatch 'Timeout|prelogin|network|TCP Provider|forcibly closed|handshake')) {
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
      if ($label) { $text | Set-Content (Join-Path $evDir "$label.txt") -Encoding UTF8 }
      throw "sqlcmd exit=$exit label=$label attempt=$attempts`n$text"
    }
    Start-Sleep -Seconds (3 * $attempts)
  }
}
function Invoke-Local([string]$q,[string]$label) { Invoke-Sql "localhost" "SB2" "sa" $localPwd $q $label }
function Invoke-Cloud([string]$q,[string]$label) { Invoke-Sql "sql8006.site4now.net" "db_abe8c0_sb2" "db_abe8c0_sb2_admin" $cloudPwd $q $label }
function Run-Once([string]$label) {
  Push-Location "D:\Dev\SB2-Cloud-Runtime"
  try {
    $attempts = 0
    while ($true) {
      $attempts++
      $out = & ".\SB.SyncAgent.exe" /once 2>&1 | Out-String
      $out | Set-Content (Join-Path $evDir ($label + "_once_a" + $attempts + ".txt")) -Encoding UTF8
      if ($LASTEXITCODE -eq 0 -and $out -match 'Sync cycle completed') {
        Write-Host "ONCE $label OK (a$attempts)"
        return $out
      }
      if ($attempts -ge 3 -or ($out -notmatch 'Timeout|prelogin|network|TCP Provider|semaphore|transport')) {
        throw "/once failed $label exit=$LASTEXITCODE attempt=$attempts`n$out"
      }
      Write-Host "ONCE $label retry after transport flake a$attempts"
      Start-Sleep -Seconds 5
    }
  } finally { Pop-Location }
}
function Parse-Id([string]$text, [string]$tag) {
  foreach ($line in ($text -split "`r?`n")) {
    if ($line -match ("^" + [regex]::Escape($tag) + "`t\s*(\d+)")) { return [long]$Matches[1] }
    if ($line -match ("^" + [regex]::Escape($tag) + "\s+(\d+)\s*$")) { return [long]$Matches[1] }
  }
  throw "Could not parse id for $tag from: $text"
}
function Scalar-Int([string]$text) {
  foreach ($line in ($text -split "`r?`n")) {
    if ($line -match '^\s*(\d+)\s*$') { return [int]$Matches[1] }
  }
  return -1
}
function Get-PendingCounts([string]$label) {
  $q = @"
SET NOCOUNT ON;
SELECT ISNULL(SUM(CASE WHEN Direction='L2C' AND Status='Pending' THEN 1 ELSE 0 END),0) AS L2C_Pending,
       ISNULL(SUM(CASE WHEN Direction='C2L' AND Status='Pending' THEN 1 ELSE 0 END),0) AS C2L_Pending,
       ISNULL(SUM(CASE WHEN Status='Syncing' THEN 1 ELSE 0 END),0) AS Syncing,
       ISNULL(SUM(CASE WHEN Status='DeadLetter' THEN 1 ELSE 0 END),0) AS DeadLetter
FROM dbo.SyncOutbox WHERE Status IN ('Pending','Syncing','DeadLetter');
"@
  $l = Invoke-Local $q "${label}_pend_L"
  $c = Invoke-Cloud $q "${label}_pend_C"
  function Parse-Counts($text) {
    foreach ($line in ($text -split "`r?`n")) {
      if ($line -match '^\s*(\d+)\t\s*(\d+)\t\s*(\d+)\t\s*(\d+)\s*$') {
        return @{ L2C=[int]$Matches[1]; C2L=[int]$Matches[2]; Syncing=[int]$Matches[3]; Dead=[int]$Matches[4]; Raw=$text }
      }
    }
    return @{ L2C=-1; C2L=-1; Syncing=-1; Dead=-1; Raw=$text }
  }
  $lp = Parse-Counts $l; $cp = Parse-Counts $c
  Write-Host ("PENDING {0}: Local L2C={1} C2L={2} Syn={3} Dead={4} | Cloud L2C={5} C2L={6} Syn={7} Dead={8}" -f $label,$lp.L2C,$lp.C2L,$lp.Syncing,$lp.Dead,$cp.L2C,$cp.C2L,$cp.Syncing,$cp.Dead)
  return @{ Local=$lp; Cloud=$cp }
}
function Assert-PendingZero([string]$label) {
  $p = Get-PendingCounts $label
  $ok = ($p.Local.L2C -eq 0 -and $p.Local.C2L -eq 0 -and $p.Local.Syncing -eq 0 -and $p.Local.Dead -eq 0 -and $p.Cloud.L2C -eq 0 -and $p.Cloud.C2L -eq 0 -and $p.Cloud.Syncing -eq 0 -and $p.Cloud.Dead -eq 0)
  if (-not $ok) {
    $dump = "SET NOCOUNT ON; SELECT OutboxID, Direction, TableName, Operation, Status, LEFT(ISNULL(LastError,''),200) LastError, PrimaryKeyJson FROM dbo.SyncOutbox WHERE Status IN ('Pending','Syncing','DeadLetter') ORDER BY OutboxID;"
    Invoke-Local $dump "${label}_resid_L" | Out-Null
    Invoke-Cloud $dump "${label}_resid_C" | Out-Null
  }
  return @{ Ok=$ok; Pending=$p }
}
function Set-Result([string]$cell,[string]$result,[string]$evidence) {
  $results[$cell] = [pscustomobject]@{ Suite=$suiteName; Result=$result; Evidence=$evidence }
  Write-Host ("RESULT {0} = {1} | {2}" -f $cell,$result,$evidence)
}

Write-Host "MARKER=$marker SUITE=$suiteName"

# ---- Family insert SQL templates (minimal disposable rows) ----
# CodeID 139/203 used previously; Location 1/7; Supplier 2/40; Customer 1071; AccountName IDs 26/198/288/289
$Fam = @{}

$Fam['Sale'] = @{
  Head='SaleHead'; Detail='SaleDetail'
  InsHead = "INSERT INTO dbo.SaleHead (Date, AutoID, LocationID, CustomerID, PaymentID, AccountID, Remark, Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, TotalBalance, Deleted, UserID) VALUES (GETDATE(), N'E2E', 1, 1071, 1, 288, N'{0}', 0, 0, 0, 0, 0, 0, 0, 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.SaleDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['Purchase'] = @{
  Head='PurchaseHead'; Detail='PurchaseDetail'
  InsHead = "INSERT INTO dbo.PurchaseHead (Date, AutoID, DocumentID, StockReceived, LocationID, SupplierID, CurrencyID, PaymentID, ExgRate, Remark, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 0, 7, 40, 1, 2, 1.0, N'{0}', 0, 0, 0, 0, 0, 0, 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.PurchaseDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 139, 0, 0, 0);"
}
$Fam['Transfer'] = @{
  Head='TransferHead'; Detail='TransferDetail'
  InsHead = "INSERT INTO dbo.TransferHead (Date, AutoID, DocumentID, FromLocID, ToLocID, Remark, TotalAmount, TotalWeight, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 2, 1, N'{0}', 0, 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.TransferDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 2619, 0, 0, 0);"
}
$Fam['Adjustment'] = @{
  Head='AdjustmentHead'; Detail='AdjustmentDetail'
  InsHead = "INSERT INTO dbo.AdjustmentHead (Date, AutoID, DocumentID, LocationID, Remark, TotalAmount, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 1, N'{0}', 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.AdjustmentDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['StockReceive'] = @{
  Head='StockReceiveHead'; Detail='StockReceiveDetail'
  InsHead = "INSERT INTO dbo.StockReceiveHead (Date, AutoID, DocumentID, LocationID, SupplierID, Remark, Deleted, UserID, ExgRate) VALUES (GETDATE(), N'E2E', N'E2E', 5, 38, N'{0}', 0, 5, 1.0);"
  InsDetail = "INSERT INTO dbo.StockReceiveDetail (RefID, Sr, CodeID, Qty, Price) VALUES ({0}, 1, 203, 0, 0);"
}
$Fam['IncomeExpense'] = @{
  Head='IncomeExpenseHead'; Detail='IncomeExpenseDetail'
  InsHead = "INSERT INTO dbo.IncomeExpenseHead (Date, AutoID, DocumentID, CashbookTypeID, CurrencyID, AccountID, ExgRate, Remark, TotalIncome, TotalExpense, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 4, 1, 288, 1.0, N'{0}', 0, 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.IncomeExpenseDetail (RefID, Sr, DetailAccountID, SourceID, Description, Debit, Credit, ExgRate, MMKDebit, MMKCredit) VALUES ({0}, 1, 26, NULL, N'E2E', 0, 0, 1, 0, 0);"
}
$Fam['StockOpening'] = @{
  Head='StockOpeningHead'; Detail='StockOpeningDetail'
  InsHead = "INSERT INTO dbo.StockOpeningHead (Date, AutoID, DocumentID, LocationID, Remark, Amount, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 1, N'{0}', 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.StockOpeningDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['AccountOpening'] = @{
  Head='AccountOpeningHead'; Detail='AccountOpeningDetail'
  InsHead = "INSERT INTO dbo.AccountOpeningHead (Date, AutoID, DocumentID, CurrencyID, ExgRate, TotalDebit, TotalCredit, Remark, UserID, Deleted) VALUES (GETDATE(), N'E2E', N'E2E', 1, 1.0, 0, 0, N'{0}', 5, 0);"
  InsDetail = "INSERT INTO dbo.AccountOpeningDetail (RefID, Sr, AccountID, Description, Debit, Credit) VALUES ({0}, 1, 198, N'E2E', 0, 0);"
}
$Fam['CustomerOpening'] = @{
  Head='CustomerOpeningHead'; Detail='CustomerOpeningDetail'
  InsHead = "INSERT INTO dbo.CustomerOpeningHead (isOpening, Date, AutoID, DocumentID, Remark, Amount, Deleted, UserID) VALUES (1, GETDATE(), N'E2E', N'E2E', N'{0}', 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.CustomerOpeningDetail (RefID, Sr, CustomerID, Amount) VALUES ({0}, 1, 1071, 0);"
}
$Fam['SupplierOpening'] = @{
  Head='SupplierOpeningHead'; Detail='SupplierOpeningDetail'
  InsHead = "INSERT INTO dbo.SupplierOpeningHead (isOpening, Date, AutoID, DocumentID, CurrencyID, ExgRate, Remark, Amount, UserID, Deleted) VALUES (1, GETDATE(), N'E2E', N'E2E', 1, 1.0, N'{0}', 0, 5, 0);"
  InsDetail = "INSERT INTO dbo.SupplierOpeningDetail (RefID, Sr, SupplierID, Amount) VALUES ({0}, 1, 2, 0);"
}
$Fam['ManufacturerOpening'] = @{
  Head='ManufacturerOpeningHead'; Detail='ManufacturerOpeningDetail'
  InsHead = "INSERT INTO dbo.ManufacturerOpeningHead (isOpening, Date, AutoID, DocumentID, Remark, Amount, Deleted, UserID) VALUES (1, GETDATE(), N'E2E', N'E2E', N'{0}', 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.ManufacturerOpeningDetail (RefID, Sr, ManufacturerID, Amount) VALUES ({0}, 1, 1, 0);"
}
$Fam['ReturnReceive'] = @{
  Head='ReturnReceiveHead'; Detail='ReturnReceiveDetail'
  InsHead = "INSERT INTO dbo.ReturnReceiveHead (Date, AutoID, DocumentID, LocationID, SupplierID, Remark, Amount, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 1, 2, N'{0}', 0, 0, 5);"
  InsDetail = "INSERT INTO dbo.ReturnReceiveDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['RawIssue'] = @{
  Head='RawIssueHead'; Detail='RawIssueDetail'
  InsHead = "INSERT INTO dbo.RawIssueHead (Date, AutoID, DocumentID, LocationID, Remark, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 1, N'{0}', 0, 5);"
  InsDetail = "INSERT INTO dbo.RawIssueDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['FinishGoods'] = @{
  Head='FinishGoodsHead'; Detail='FinishGoodsDetail'
  InsHead = "INSERT INTO dbo.FinishGoodsHead (Date, AutoID, DocumentID, LocationID, Remark, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 1, N'{0}', 0, 5);"
  InsDetail = "INSERT INTO dbo.FinishGoodsDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['ReturnStock'] = @{
  Head='ReturnStockHead'; Detail='ReturnStockDetail'
  InsHead = "INSERT INTO dbo.ReturnStockHead (Date, AutoID, DocumentID, LocationID, Remark, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 1, N'{0}', 0, 5);"
  InsDetail = "INSERT INTO dbo.ReturnStockDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['GetStock'] = @{
  Head='GetStockHead'; Detail='GetStockDetail'
  InsHead = "INSERT INTO dbo.GetStockHead (Date, AutoID, DocumentID, LocationID, Remark, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 1, N'{0}', 0, 5);"
  InsDetail = "INSERT INTO dbo.GetStockDetail (RefID, Sr, CodeID, Qty, Price, Amount) VALUES ({0}, 1, 203, 0, 0, 0);"
}
$Fam['CustSupTransfer'] = @{
  Head='CustSupTransfer'; Detail=$null
  InsHead = "INSERT INTO dbo.CustSupTransfer (Date, AutoID, DocumentID, FromAcctID, FromSourceID, ToAcctID, ToSourceID, Amount, Remark, Deleted, UserID) VALUES (GETDATE(), N'E2E', N'E2E', 289, 6293, 26, 2, 0, N'{0}', 0, 5);"
  InsDetail = $null
}

function Insert-Head([string]$side,[hashtable]$f,[string]$remark,[string]$label) {
  $sql = "SET NOCOUNT ON;`n" + ($f.InsHead -f $remark) + "`nSELECT 'HEADID' AS Tag, CAST(SCOPE_IDENTITY() AS bigint) AS ID;"
  if ($side -eq 'Local') { $t = Invoke-Local $sql $label } else { $t = Invoke-Cloud $sql $label }
  return (Parse-Id $t 'HEADID')
}
function Insert-Detail([string]$side,[hashtable]$f,[long]$refId,[string]$label) {
  if (-not $f.Detail) { return $null }
  $sql = "SET NOCOUNT ON;`n" + ($f.InsDetail -f $refId) + "`nSELECT 'DETAILID' AS Tag, CAST(SCOPE_IDENTITY() AS bigint) AS ID;"
  if ($side -eq 'Local') { $t = Invoke-Local $sql $label } else { $t = Invoke-Cloud $sql $label }
  return (Parse-Id $t 'DETAILID')
}
function Table-Exists([string]$side,[string]$name) {
  $q = "SET NOCOUNT ON; SELECT CASE WHEN OBJECT_ID(N'dbo.$name','U') IS NULL THEN 0 ELSE 1 END;"
  if ($side -eq 'Local') { return (Scalar-Int (Invoke-Local $q "exists_L_$name")) }
  return (Scalar-Int (Invoke-Cloud $q "exists_C_$name"))
}

function Run-FamilyFull([string]$name, [switch]$SpotOnly) {
  $f = $Fam[$name]
  if (-not $f) { Set-Result "${name}_META" "SKIP" "No family definition"; return }
  if ((Table-Exists 'Local' $f.Head) -ne 1) {
    Set-Result "${name}_META" "SKIP" "Missing table $($f.Head)"
    $skips[$name] = "Missing table $($f.Head)"
    return
  }
  Write-Host "======== FAMILY $name SpotOnly=$SpotOnly ========"
  $H = $f.Head; $D = $f.Detail

  # 1) NEW L2C
  $cell = "${name}_NEW_L2C"
  try {
    $hid = Insert-Head 'Local' $f "${marker}_${name}_NEW_L2C" "${cell}_ins"
    $did = $null
    if ($D) { $did = Insert-Detail 'Local' $f $hid "${cell}_det" }
    Run-Once $cell
    $cHead = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid AND Remark=N'${marker}_${name}_NEW_L2C') THEN 1 ELSE 0 END;" "${cell}_chkH")
    $cDet = 1
    if ($D) { $cDet = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_chkD") }
    $pend = Assert-PendingZero $cell
    $zoneOk = $hid -lt 2000000000
    $pass = ($cHead -eq 1) -and ($cDet -eq 1) -and $pend.Ok -and $zoneOk
    Set-Result $cell $(if ($pass) {'PASS'} else {'FAIL'}) "LocalHead=$hid Detail=$did CloudHead=$cHead CloudDet=$cDet zoneLocal=$zoneOk Pending0=$($pend.Ok)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  # 2) NEW C2L
  $cell = "${name}_NEW_C2L"
  try {
    $hid = Insert-Head 'Cloud' $f "${marker}_${name}_NEW_C2L" "${cell}_ins"
    $did = $null
    if ($D) { $did = Insert-Detail 'Cloud' $f $hid "${cell}_det" }
    Run-Once $cell
    $lHead = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid AND Remark=N'${marker}_${name}_NEW_C2L') THEN 1 ELSE 0 END;" "${cell}_chkH")
    $lDet = 1
    if ($D) { $lDet = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_chkD") }
    $pend = Assert-PendingZero $cell
    $zoneOk = $hid -ge 2000000000
    $pass = ($lHead -eq 1) -and ($lDet -eq 1) -and $pend.Ok -and $zoneOk
    Set-Result $cell $(if ($pass) {'PASS'} else {'FAIL'}) "CloudHead=$hid Detail=$did LocalHead=$lHead LocalDet=$lDet zone2e9=$zoneOk Pending0=$($pend.Ok)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  if ($SpotOnly) {
    # Spot-check: one EDIT L2C only (prior 6/6 already PASS)
    $cell = "${name}_SPOT_EDIT_L2C"
    try {
      $hid = Insert-Head 'Local' $f "${marker}_${name}_SPOT_SETUP" "${cell}_ins"
      Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
      $edit = "${marker}_${name}_SPOT_EDIT"
      Invoke-Local "SET NOCOUNT ON; UPDATE dbo.$H SET Remark=N'$edit' WHERE ID=$hid;" "${cell}_upd" | Out-Null
      Run-Once $cell
      $match = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid AND Remark=N'$edit') THEN 1 ELSE 0 END;" "${cell}_chk")
      $pend = Assert-PendingZero $cell
      Set-Result $cell $(if (($match -eq 1) -and $pend.Ok) {'PASS'} else {'FAIL'}) "Head=$hid CloudMatch=$match Pending0=$($pend.Ok)"
    } catch { Set-Result $cell 'FAIL' $_.Exception.Message }
    return
  }

  # 3) EDIT L2C
  $cell = "${name}_EDIT_L2C"
  try {
    $hid = Insert-Head 'Local' $f "${marker}_${name}_EDIT_L2C_SETUP" "${cell}_ins"
    Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
    $edit = "${marker}_${name}_EDIT_L2C"
    Invoke-Local "SET NOCOUNT ON; UPDATE dbo.$H SET Remark=N'$edit' WHERE ID=$hid;" "${cell}_upd" | Out-Null
    Run-Once $cell
    $match = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid AND Remark=N'$edit') THEN 1 ELSE 0 END;" "${cell}_chk")
    $pend = Assert-PendingZero $cell
    Set-Result $cell $(if (($match -eq 1) -and $pend.Ok) {'PASS'} else {'FAIL'}) "Head=$hid CloudMatch=$match Pending0=$($pend.Ok)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  # 3b) EDIT C2L
  $cell = "${name}_EDIT_C2L"
  try {
    $hid = Insert-Head 'Cloud' $f "${marker}_${name}_EDIT_C2L_SETUP" "${cell}_ins"
    Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
    $edit = "${marker}_${name}_EDIT_C2L"
    Invoke-Cloud "SET NOCOUNT ON; UPDATE dbo.$H SET Remark=N'$edit' WHERE ID=$hid;" "${cell}_upd" | Out-Null
    Run-Once $cell
    $match = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid AND Remark=N'$edit') THEN 1 ELSE 0 END;" "${cell}_chk")
    $pend = Assert-PendingZero $cell
    $zoneOk = $hid -ge 2000000000
    Set-Result $cell $(if (($match -eq 1) -and $pend.Ok -and $zoneOk) {'PASS'} else {'FAIL'}) "Head=$hid zone2e9=$zoneOk LocalMatch=$match Pending0=$($pend.Ok)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  if ($D) {
    # 4) DETAIL hard-delete L2C
    $cell = "${name}_DETHARD_L2C"
    try {
      $hid = Insert-Head 'Local' $f "${marker}_${name}_DETHARD_L2C_SETUP" "${cell}_ins"
      $did = Insert-Detail 'Local' $f $hid "${cell}_det"
      Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
      Invoke-Local "SET NOCOUNT ON; DELETE FROM dbo.$D WHERE ID=$did;" "${cell}_del" | Out-Null
      Run-Once $cell
      $lAbs = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_L")
      $cAbs = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_C")
      $miss = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Status='Pending' AND LastError LIKE '%Applied but row missing%';" "${cell}_miss")
      $pend = Assert-PendingZero $cell
      Set-Result $cell $(if (($lAbs -eq 0) -and ($cAbs -eq 0) -and ($miss -eq 0) -and $pend.Ok) {'PASS'} else {'FAIL'}) "Detail=$did Head=$hid L=$lAbs C=$cAbs Miss=$miss Pending0=$($pend.Ok)"
    } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

    # 4b) DETAIL hard-delete C2L
    $cell = "${name}_DETHARD_C2L"
    try {
      $hid = Insert-Head 'Cloud' $f "${marker}_${name}_DETHARD_C2L_SETUP" "${cell}_ins"
      $did = Insert-Detail 'Cloud' $f $hid "${cell}_det"
      Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
      Invoke-Cloud "SET NOCOUNT ON; DELETE FROM dbo.$D WHERE ID=$did;" "${cell}_del" | Out-Null
      Run-Once $cell
      $lAbs = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_L")
      $cAbs = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_C")
      $miss = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Status='Pending' AND LastError LIKE '%Applied but row missing%';" "${cell}_miss")
      $pend = Assert-PendingZero $cell
      Set-Result $cell $(if (($lAbs -eq 0) -and ($cAbs -eq 0) -and ($miss -eq 0) -and $pend.Ok) {'PASS'} else {'FAIL'}) "Detail=$did Head=$hid L=$lAbs C=$cAbs Miss=$miss Pending0=$($pend.Ok)"
    } catch { Set-Result $cell 'FAIL' $_.Exception.Message }
  } else {
    Set-Result "${name}_DETHARD_L2C" "SKIP" "No Detail table"
    Set-Result "${name}_DETHARD_C2L" "SKIP" "No Detail table"
  }

  # 5) HEAD soft-delete L2C
  $cell = "${name}_HEADSOFT_L2C"
  try {
    $hid = Insert-Head 'Local' $f "${marker}_${name}_HEADSOFT_L2C_SETUP" "${cell}_ins"
    Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
    Invoke-Local "SET NOCOUNT ON; UPDATE dbo.$H SET Deleted=1 WHERE ID=$hid;" "${cell}_soft" | Out-Null
    $srcOk = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN Deleted=1 AND IsDeleted=1 AND DeletedAt IS NOT NULL THEN 1 ELSE 0 END FROM dbo.$H WHERE ID=$hid;" "${cell}_src")
    $opD = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT TOP 1 CASE WHEN Operation='D' THEN 1 ELSE 0 END FROM dbo.SyncOutbox WHERE TableName='$H' AND Direction='L2C' AND PrimaryKeyJson LIKE '%$hid%' AND Operation IN ('D','U') ORDER BY OutboxID DESC;" "${cell}_op")
    Run-Once $cell
    $cloudOk = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid AND Deleted=1 AND IsDeleted=1) THEN 1 ELSE 0 END;" "${cell}_cloud")
    $present = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid) THEN 1 ELSE 0 END;" "${cell}_present")
    $pend = Assert-PendingZero $cell
    $pass = ($srcOk -eq 1) -and ($opD -eq 1) -and ($cloudOk -eq 1) -and ($present -eq 1) -and $pend.Ok
    Set-Result $cell $(if ($pass) {'PASS'} else {'FAIL'}) "Head=$hid OpD=$opD Src=$srcOk Cloud11=$cloudOk Present=$present Pending0=$($pend.Ok)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  # 5b) HEAD soft-delete C2L
  $cell = "${name}_HEADSOFT_C2L"
  try {
    $hid = Insert-Head 'Cloud' $f "${marker}_${name}_HEADSOFT_C2L_SETUP" "${cell}_ins"
    Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
    Invoke-Cloud "SET NOCOUNT ON; UPDATE dbo.$H SET Deleted=1 WHERE ID=$hid;" "${cell}_soft" | Out-Null
    $srcOk = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN Deleted=1 AND IsDeleted=1 AND DeletedAt IS NOT NULL THEN 1 ELSE 0 END FROM dbo.$H WHERE ID=$hid;" "${cell}_src")
    $opD = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT TOP 1 CASE WHEN Operation='D' THEN 1 ELSE 0 END FROM dbo.SyncOutbox WHERE TableName='$H' AND Direction='C2L' AND PrimaryKeyJson LIKE '%$hid%' AND Operation IN ('D','U') ORDER BY OutboxID DESC;" "${cell}_op")
    Run-Once $cell
    $localOk = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid AND Deleted=1 AND IsDeleted=1) THEN 1 ELSE 0 END;" "${cell}_local")
    $present = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid) THEN 1 ELSE 0 END;" "${cell}_present")
    $pend = Assert-PendingZero $cell
    $pass = ($srcOk -eq 1) -and ($opD -eq 1) -and ($localOk -eq 1) -and ($present -eq 1) -and $pend.Ok
    Set-Result $cell $(if ($pass) {'PASS'} else {'FAIL'}) "Head=$hid OpD=$opD Src=$srcOk Local11=$localOk Present=$present Pending0=$($pend.Ok)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }
}

function Run-Conflicts {
  Write-Host "======== CONFLICT PROBES (Sale) ========"
  $f = $Fam['Sale']; $H = 'SaleHead'; $D = 'SaleDetail'

  # C1: Same Head edited Local AND Cloud before sync (different Remarks)
  $cell = 'CONFLICT_C1_DualEdit'
  try {
    $hid = Insert-Head 'Local' $f "${marker}_C1_SETUP" "${cell}_ins"
    Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
    $rL = "${marker}_C1_LOCAL"; $rC = "${marker}_C1_CLOUD"
    Invoke-Local "SET NOCOUNT ON; UPDATE dbo.$H SET Remark=N'$rL' WHERE ID=$hid;" "${cell}_updL" | Out-Null
    Invoke-Cloud "SET NOCOUNT ON; UPDATE dbo.$H SET Remark=N'$rC' WHERE ID=$hid;" "${cell}_updC" | Out-Null
    # Capture pending outbox both sides before once
    $obL = Invoke-Local "SET NOCOUNT ON; SELECT TOP 3 OutboxID, Direction, Operation, Status, LEFT(ISNULL(LastError,''),120) LE FROM dbo.SyncOutbox WHERE TableName='$H' AND PrimaryKeyJson LIKE '%$hid%' AND Status='Pending' ORDER BY OutboxID DESC;" "${cell}_obL"
    $obC = Invoke-Cloud "SET NOCOUNT ON; SELECT TOP 3 OutboxID, Direction, Operation, Status, LEFT(ISNULL(LastError,''),120) LE FROM dbo.SyncOutbox WHERE TableName='$H' AND PrimaryKeyJson LIKE '%$hid%' AND Status='Pending' ORDER BY OutboxID DESC;" "${cell}_obC"
    Run-Once "${cell}_once1"
    Run-Once "${cell}_once2"
    $finalL = Invoke-Local "SET NOCOUNT ON; SELECT ID, Remark, Deleted, IsDeleted FROM dbo.$H WHERE ID=$hid;" "${cell}_finalL"
    $finalC = Invoke-Cloud "SET NOCOUNT ON; SELECT ID, Remark, Deleted, IsDeleted FROM dbo.$H WHERE ID=$hid;" "${cell}_finalC"
    $obAfterL = Invoke-Local "SET NOCOUNT ON; SELECT TOP 5 OutboxID, Direction, Operation, Status, LEFT(ISNULL(LastError,''),160) LE FROM dbo.SyncOutbox WHERE TableName='$H' AND PrimaryKeyJson LIKE '%$hid%' ORDER BY OutboxID DESC;" "${cell}_obAfterL"
    $obAfterC = Invoke-Cloud "SET NOCOUNT ON; SELECT TOP 5 OutboxID, Direction, Operation, Status, LEFT(ISNULL(LastError,''),160) LE FROM dbo.SyncOutbox WHERE TableName='$H' AND PrimaryKeyJson LIKE '%$hid%' ORDER BY OutboxID DESC;" "${cell}_obAfterC"
    $pend = Assert-PendingZero $cell
    $remL = if ($finalL -match $rL) {'LOCAL'} elseif ($finalL -match $rC) {'CLOUD'} else {'OTHER'}
    $remC = if ($finalC -match $rL) {'LOCAL'} elseif ($finalC -match $rC) {'CLOUD'} else {'OTHER'}
    $consistent = ($remL -eq $remC) -and ($remL -ne 'OTHER')
    # Policy: must not leave stuck pending; document winner
    $pass = $pend.Ok -and ($consistent -or ($remL -ne 'OTHER' -and $remC -ne 'OTHER'))
    # If both sides have a known remark but differ, still FAIL consistency but note policy if pending cleared
    if ($pend.Ok -and -not $consistent) {
      Set-Result $cell 'FAIL' "Dual-edit left inconsistent Remarks LocalWinner=$remL CloudWinner=$remC Pending0=True (policy=document; not stuck). FinalL=$($finalL -replace '\s+',' ') FinalC=$($finalC -replace '\s+',' ')"
    } elseif ($pass -and $consistent) {
      Set-Result $cell 'PASS' "Winner both=$remL Pending0=True FinalL=$($finalL -replace '\s+',' ') FinalC=$($finalC -replace '\s+',' ')"
    } else {
      Set-Result $cell 'FAIL' "Local=$remL Cloud=$remC Pending0=$($pend.Ok) FinalL=$($finalL -replace '\s+',' ') FinalC=$($finalC -replace '\s+',' ')"
    }
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  # C2: Local soft-deletes Head while Cloud edits same Head
  $cell = 'CONFLICT_C2_LocalSoft_CloudEdit'
  try {
    $hid = Insert-Head 'Local' $f "${marker}_C2_SETUP" "${cell}_ins"
    Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
    Invoke-Local "SET NOCOUNT ON; UPDATE dbo.$H SET Deleted=1 WHERE ID=$hid;" "${cell}_softL" | Out-Null
    Invoke-Cloud "SET NOCOUNT ON; UPDATE dbo.$H SET Remark=N'${marker}_C2_CLOUD_EDIT' WHERE ID=$hid;" "${cell}_editC" | Out-Null
    Run-Once "${cell}_once1"
    Run-Once "${cell}_once2"
    $finalL = Invoke-Local "SET NOCOUNT ON; SELECT ID, Remark, Deleted, IsDeleted FROM dbo.$H WHERE ID=$hid;" "${cell}_finalL"
    $finalC = Invoke-Cloud "SET NOCOUNT ON; SELECT ID, Remark, Deleted, IsDeleted FROM dbo.$H WHERE ID=$hid;" "${cell}_finalC"
    $ob = Invoke-Local "SET NOCOUNT ON; SELECT TOP 5 OutboxID, Direction, Operation, Status, LEFT(ISNULL(LastError,''),120) LE FROM dbo.SyncOutbox WHERE TableName='$H' AND PrimaryKeyJson LIKE '%$hid%' ORDER BY OutboxID DESC;" "${cell}_ob"
    $obC = Invoke-Cloud "SET NOCOUNT ON; SELECT TOP 5 OutboxID, Direction, Operation, Status, LEFT(ISNULL(LastError,''),120) LE FROM dbo.SyncOutbox WHERE TableName='$H' AND PrimaryKeyJson LIKE '%$hid%' ORDER BY OutboxID DESC;" "${cell}_obC"
    $pend = Assert-PendingZero $cell
    $presentBoth = (Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid) THEN 1 ELSE 0 END;" "${cell}_pL")) -eq 1 -and (Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$H WHERE ID=$hid) THEN 1 ELSE 0 END;" "${cell}_pC")) -eq 1
    Set-Result $cell $(if ($pend.Ok -and $presentBoth) {'PASS'} else {'FAIL'}) "Pending0=$($pend.Ok) PresentBoth=$presentBoth FinalL=$($finalL -replace '\s+',' ') FinalC=$($finalC -replace '\s+',' ') (document winner: soft-delete vs edit)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  # C3: Both sides DELETE same Detail
  $cell = 'CONFLICT_C3_DualDetailHardDel'
  try {
    $hid = Insert-Head 'Local' $f "${marker}_C3_SETUP" "${cell}_ins"
    $did = Insert-Detail 'Local' $f $hid "${cell}_det"
    Run-Once "${cell}_setup"; $null = Assert-PendingZero "${cell}_setup"
    # Ensure detail present both
    $cDet = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_preC")
    if ($cDet -ne 1) { throw "Detail $did not on Cloud before dual delete" }
    Invoke-Local "SET NOCOUNT ON; DELETE FROM dbo.$D WHERE ID=$did;" "${cell}_delL" | Out-Null
    Invoke-Cloud "SET NOCOUNT ON; DELETE FROM dbo.$D WHERE ID=$did;" "${cell}_delC" | Out-Null
    Run-Once "${cell}_once1"
    Run-Once "${cell}_once2"
    $lAbs = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_L")
    $cAbs = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.$D WHERE ID=$did) THEN 1 ELSE 0 END;" "${cell}_C")
    $missL = Scalar-Int (Invoke-Local "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Status IN ('Pending','DeadLetter') AND LastError LIKE '%row missing%';" "${cell}_missL")
    $missC = Scalar-Int (Invoke-Cloud "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Status IN ('Pending','DeadLetter') AND LastError LIKE '%row missing%';" "${cell}_missC")
    $pend = Assert-PendingZero $cell
    $pass = ($lAbs -eq 0) -and ($cAbs -eq 0) -and ($missL -eq 0) -and ($missC -eq 0) -and $pend.Ok
    Set-Result $cell $(if ($pass) {'PASS'} else {'FAIL'}) "Detail=$did L=$lAbs C=$cAbs MissL=$missL MissC=$missC Pending0=$($pend.Ok)"
  } catch { Set-Result $cell 'FAIL' $_.Exception.Message }

  # C4: Colliding insert same ID â€” skip if identity-unique (always)
  $cell = 'CONFLICT_C4_CollidingID'
  Set-Result $cell 'SKIP' "IDs always identity-unique; Cloud reseeded >=2e9, Local <<2e9; no business-key collision path for SaleHead without IDENTITY_INSERT (forbidden in matrix)"
}

# ---- MAIN ----
$baseline = Assert-PendingZero "00_baseline"
if (-not $baseline.Ok) { throw "Baseline Pending not zero; abort Suite A" }

# SKIPs
$skips['Journal'] = 'JournalHead/JournalDetail tables absent'
$skips['Manufacture'] = 'ManufactureHead/ManufactureDetail absent (use RawIssue/FinishGoods families)'
$skips['Stock'] = 'No StockHead; covered as StockReceive family (StockReceiveHead/Detail present). StockDetail exists as orphan detail pack name only.'
Set-Result 'Journal_META' 'SKIP' $skips['Journal']
Set-Result 'Manufacture_META' 'SKIP' $skips['Manufacture']
Set-Result 'Stock_META' 'SKIP' $skips['Stock']

# Spot-only for already-green Sale/Purchase/Transfer (+ NEW both ways inside SpotOnly=false path for NEW... wait SpotOnly still does NEW)
# SpotOnly does NEW L2C + NEW C2L + one EDIT L2C spot
Run-FamilyFull 'Sale' -SpotOnly
Run-FamilyFull 'Purchase' -SpotOnly
Run-FamilyFull 'Transfer' -SpotOnly

# Full matrix for remaining families
$full = @(
  'Adjustment','StockReceive','IncomeExpense',
  'StockOpening','AccountOpening','CustomerOpening','SupplierOpening','ManufacturerOpening',
  'ReturnReceive','RawIssue','FinishGoods','ReturnStock','GetStock','CustSupTransfer'
)
foreach ($n in $full) { Run-FamilyFull $n }

Run-Conflicts

$final = Assert-PendingZero "99_final"
$passN = @($results.Values | Where-Object { $_.Result -eq 'PASS' }).Count
$failN = @($results.Values | Where-Object { $_.Result -eq 'FAIL' }).Count
$skipN = @($results.Values | Where-Object { $_.Result -eq 'SKIP' }).Count
$overall = if (($failN -eq 0) -and ($final.Ok) -and ($passN -gt 0)) { 'PASS' } else { 'FAIL' }

$summary = [ordered]@{
  Suite = $suiteName
  Marker = $marker
  Overall = $overall
  Pass = $passN
  Fail = $failN
  Skip = $skipN
  FinalPendingOk = $final.Ok
  FinalPending = $final.Pending
  Skips = $skips
  Results = $results
}
$summary | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $evDir "suiteA_results.json") -Encoding UTF8
Write-Host "======== SUITE A SUMMARY Overall=$overall PASS=$passN FAIL=$failN SKIP=$skipN FinalPending0=$($final.Ok) ========"
foreach ($k in $results.Keys) {
  $r = $results[$k]
  Write-Host ("{0}`t{1}`t{2}" -f $k,$r.Result,$r.Evidence)
}
if ($overall -ne 'PASS') { exit 2 } else { exit 0 }
