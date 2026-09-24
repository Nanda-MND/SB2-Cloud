# SB2 — Bank Charges / Sales port checklist

SB branch `cursor/cheque-print-and-balance-filters` ရဲ့ Bank Charges logic ကို **SB2** workspace မှာ port လုပ်ရန် guideline။

| | |
|--|--|
| Reference PR | https://github.com/Nanda-MND/SB/pull/1 |
| Source branch | `cursor/cheque-print-and-balance-filters` |
| SB deploy checklist | `docs/SB_BankCharges_Deploy.md` |
| GL / balance notes | `docs/sql/Sale_BankPosting_ExcludeAddAmount.md` |

> ဒီ SB cloud agent က SB2 repo ကို edit မလုပ်နိုင်ပါ။ အောက်ဆုံး **Prompt** ကို SB2 cloud agent ထဲ paste လုပ်ပါ။

---

## Fee calculation (မပြောင်းရ)

Account `AccountName.BankCharges` = % rate (`chg_percnet`).

Checkbox `chkBankCharges` ပေါ်နေ + checked + `0 < % < 100` ဖြစ်မှ တွက်:

```
net = Amount − Discount
AddAmount (fee) = (net / ((100 − %) / 100)) − net
```

ဥပမာ: net = 100,000၊ rate = 0.3% → `100000 / 0.997 − 100000` ≈ **301**

| Condition | Result |
|-----------|--------|
| Checkbox off / hidden | `AddAmount = 0` |
| New voucher / user changed account + rate = 0 | `AddAmount = 0` |
| **Edit** open + checkbox on + Account.BankCharges = 0 | **keep saved `AddAmount`** (မဖျက်) |

---

## Core logic (must stay consistent)

| Piece | Rule |
|--------|------|
| `SaleHead.TotalAmount` | Goods net = Amount − Discount + Tax (**fee မပါ**) |
| `SaleHead.AddAmount` | Bank transfer fee (Charges) |
| `SaleHead.IsBankCharges` | Checkbox persist |
| UI `tbTotalAmount` / Print | `TotalAmount + AddAmount` |
| GL bank/cash Debit | Amount − Discount + Tax (**exclude** AddAmount) |
| Customer receivable | `TotalAmount + AddAmount − PaidAmount` |
| After money-in | Clear fee as Credit under `ဘဏ်ဝန်ဆောင်ခ` |
| When checkbox shows | KBZQ / OB / bank-charge payment shorts **or** Credit |
| Credit + bank account | Optional Bank Charges; Account picker `SysAcctID IN (2,6)` |
| KBZQ / ayassa | Payment + Account hardcode on first customer pick |
| SaleHistory Payment filter | Account ID (e.g. APM) → any PaymentID; column shows Cash/Credit |
| New Sale defaults | KBZQ/OB → checkbox **on**; Credit → checkbox **off** (optional) |

---

## အဆင့်လိုက် လုပ်ရမည့် လုပ်ငန်းစဉ် (SB2)

### အဆင့် ၁ — Source ယူ (SB)

```powershell
Set-Location D:\Project\SB
git fetch origin
git checkout cursor/cheque-print-and-balance-filters
git pull origin cursor/cheque-print-and-balance-filters
```

သို့မဟုတ် PR #1 ကို ကိုးကား။

### အဆင့် ၂ — Code port (file-by-file merge)

SB2 က Sales/Main ကွဲနေရင် cherry-pick တစ်ခုတည်း မလုပ်ဘဲ merge လုပ်ပါ။

| File | What |
|------|------|
| `SB/frm_SalesOrder.cs` + `.Designer.cs` | `chkBankCharges`, fee formula, Credit bank accounts, preserve fee on edit, KBZQ/ayassa hardcode |
| `SB/frm_Main.cs` + `.Designer.cs` | SaleHistory Charges column, Bank Charges footer, statusStrip Spring (Total Amount မပျောက်) |
| `SB/frm_PrintSelect.cs`, `SB/frm_Preview.cs` | Print datasource `TotalAmount = TotalAmount + AddAmount` |
| `SB/ReferenceDataCache.cs` | Payment filter list includes `SysAcctID IN (2,6)` |
| `SB/Reports/Invoice.rpt`, `SaleByInvoice.rpt`, `Voucher_TM.rpt` | repo + `bin\Debug\Reports\` |

### အဆင့် ၃ — SQL (SB2 database)

`USE` ကို SB2 DB name ပြင်။ အစဉ်:

1. `docs/sql/SaleHead_IsBankCharges.sql` — `IsBankCharges` column  
2. `docs/sql/SaleHistory_AddCharges.sql` — Charges column in history  
3. `docs/sql/GeneralLedgerDetailReport_ExcludeAddAmount.sql` — GL Debit without fee  
4. `docs/sql/CustomerBalanceDetail_IncludeAddAmount.sql` — receivable + `ဘဏ်ဝန်ဆောင်ခ`  
5. `docs/sql/SaleHistory_FilterAccountPayment.sql` — APM by AccountID; Payment = Cash/Credit  
6. `docs/sql/SaleHead_TotalAmount_ExcludeAddAmount_Repair.sql` — **optional** one-time data fix  

### အဆင့် ၄ — Rebuild + reports

- SB2 rebuild  
- `.rpt` → `bin\Debug\Reports\`  

### အဆင့် ၅ — Smoke test

- [ ] New Sale + KBZQ/OB → checkbox on + fee formula  
- [ ] Credit + APM → optional checkbox; Account list SysAcctID 2,6  
- [ ] Edit + Account.BankCharges = 0 → saved `AddAmount` stays  
- [ ] SaleHistory Charges + footer Bank Charges + Total Amount  
- [ ] Payment filter APM → AccountID; Payment column Cash/Credit  
- [ ] Print total includes fee; GL bank Debit excludes fee  
- [ ] Credit balance includes fee; after receipt → `ဘဏ်ဝန်ဆောင်ခ`

---

## Prompt for SB2 cloud agent (copy/paste)

```
SB ရဲ့ Bank Charges / Sales invoice logic ကို SB2 မှာ port လုပ်ပါ။

Reference PR: https://github.com/Nanda-MND/SB/pull/1
Branch: cursor/cheque-print-and-balance-filters
Checklist: docs/SB2_BankCharges_Port.md (SB repo)

Fee formula (မပြောင်းရ):
  net = Amount - Discount
  AddAmount = (net / ((100 - AccountName.BankCharges) / 100)) - net
  when chkBankCharges visible+checked and 0 < % < 100
  Edit + rate=0 → keep saved AddAmount (မဖျက်)

Core:
1. SaleHead.IsBankCharges + chkBankCharges (Remark အောက်)
2. TotalAmount = Amount - Discount + Tax (fee မပါ); AddAmount = fee
3. UI/Print = TotalAmount + AddAmount (Invoice / SaleByInvoice / Voucher_TM)
4. SaleHistory Charges + Bank Charges footer; statusStrip Spring so Total Amount visible
5. GL Sale bank Debit = Amount-Discount+Tax (AddAmount မပါ)
6. CustomerBalanceDetail: receivable = TotalAmount+AddAmount; money-in → ဘဏ်ဝန်ဆောင်ခ Credit
7. Credit + bank Account picker SysAcctID IN (2,6); KBZQ/OB default checkbox on; Credit default off
8. KBZQ/ayassa: Payment+Account hardcode on first customer pick
9. SaleHistory Payment filter by AccountID (APM); Payment column = Cash/Credit

SQL (SB docs/sql — USE ကို SB2 DB name ပြင်):
- SaleHead_IsBankCharges.sql
- SaleHistory_AddCharges.sql
- GeneralLedgerDetailReport_ExcludeAddAmount.sql
- CustomerBalanceDetail_IncludeAddAmount.sql
- SaleHistory_FilterAccountPayment.sql
- SaleHead_TotalAmount_ExcludeAddAmount_Repair.sql (optional)

Reports ကို repo + bin\Debug\Reports copy။
လက်ရှိ SB2 branch ပေါ်မှာ file-by-file merge။ Rebuild + smoke test။
```

---

## Pull (SB source reference)

```powershell
Set-Location D:\Project\SB
git pull origin cursor/cheque-print-and-balance-filters
```
