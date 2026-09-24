# SB2 — Account Code Setup + Reports Account Code / Account Info filter port

SB branch `cursor/cheque-print-and-balance-filters` မှာလုပ်ထားတဲ့ Account Code setup + Reports filter work ကို **SB2** workspace မှာ port လုပ်ရန် guideline။

| | |
|--|--|
| Reference PR | https://github.com/Nanda-MND/SB/pull/1 |
| Source branch | `cursor/cheque-print-and-balance-filters` |
| Detail docs | `docs/Reports_AccountMultiFilter.md` |
| SQL | `docs/sql/AccountName_AcctCode.sql`, `AcctGroup_GroupCode.sql`, `AcctSubGroup_SubGroupCode.sql` |

> ဒီ SB cloud agent က SB2 repo ကို edit မလုပ်နိုင်ပါ။ အောက်ဆုံး **Prompt** ကို SB2 cloud agent ထဲ paste လုပ်ပါ (သို့) manual follow လုပ်ပါ။

---

## Scope (ဒီ port သာ)

| Area | What |
|------|------|
| Setup → Accounts | Account Code textbox (Short အပေါ်) → `AccountName.AccountCode`; list column Short မတိုင်မီ |
| Setup → Account Group | Account Code → `AcctGroup.GroupCode`; list shared column `AccountCode = GroupCode` |
| Setup → Account SubGroup | Tree New/Edit/Delete; Account Code → `AcctSubGroup.SubGroupCode`; tree text `-SubGroupCode` |
| Reports filters | **Account Code** section (`msGroupCode` / `msAccountCode`) အပေါ်၊ **Account Info** အောက်; selections merge → `FilterAcctGroup` / `FilterAccount` |

**Out of scope** (သီးခြား port): GL multi-filter SPs (`AccountFilter_Helper`, `GL_AccountMultiFilter_Patch`), GL Summary 1155, CustSupHistory, Bank Charges။  
Filter UI က ID merge လုပ်ပေးမည်၊ SP ဘက် multi-filter မရှိသေးရင် report filter အပြည့်အဝ မအလုပ်လုပ်နိုင် — SB2 မှာ GL multi-filter မရှိသေးရင် `docs/Reports_AccountMultiFilter.md` SQL အပိုင်းကို နောက်မှ ဆက်လုပ်ပါ။

---

## Core rules (မပြောင်းရ)

| Piece | Rule |
|--------|------|
| `AccountName.AccountCode` | Setup bind field name **AccountCode** (empty `AcctCode` မဟုတ်) |
| `AcctGroup.GroupCode` | Setup Account Code; list `AccountCode = A.GroupCode` (ListviewItem MenuName=`Account` shared) |
| `AcctSubGroup.SubGroupCode` | Setup Account Code; tree `Name - [Short]-SubGroupCode` |
| Tree SubGroup CRUD | Tag `B` + ID; soft-delete `Update AcctSubGroup Set Deleted = 1` |
| `LocalData.mySetup.AcctSubGroup = 20` | enum တန်ဖိုး ထပ်ထည့်၊ ရှိပြီးသား နံပါတ်များ မပြောင်း |
| Reports **Account Code** lists | `ISNULL(NULLIF(GroupCode/AccountCode,''), Short) + '-' + Name` |
| Reports **Account Info** lists | **`Short + '-' + Name` only** (code မထည့်) |
| Filter merge | Union IDs → `FilterAcctGroup` / `FilterAccount` (`MergeIdSelections`) |

---

## အဆင့်လိုက် လုပ်ရမည့် လုပ်ငန်းစဉ် (SB2)

### အဆင့် ၁ — Source ယူပါ (SB)

```powershell
Set-Location D:\Project\SB
git fetch origin
git checkout cursor/cheque-print-and-balance-filters
git pull origin cursor/cheque-print-and-balance-filters
```

သို့မဟုတ် PR #1 files ကို SB2 ဘက်က ကိုယ်တိုင် ယှဉ်ကြည့်ပါ။

### အဆင့် ၂ — Code port (ဖိုင်အလိုက် merge)

SB2 မှာ Setup/Reports ကွဲနေရင် cherry-pick တစ်ခုတည်း မလုပ်ဘဲ **file-by-file** merge လုပ်ပါ။

| File | ပြင်ရမည့်အချက် |
|------|----------------|
| `SB/LocalData.cs` | `mySetup` enum ထဲ `AcctSubGroup = 20` |
| `SB/frm_SetupDetail.cs` | Account / AcctGroup / AcctSubGroup cases — `tbAcctCode` + bind `AccountCode` / `GroupCode` / `SubGroupCode` |
| `SB/frm_SetupDetail.Designer.cs` | `tbAcctCode`, `lbAcctCode` controls |
| `SB/frm_Setup.cs` | Account list `A.AccountCode`; AcctGroup `AccountCode = A.GroupCode`; tree SubGroup New/Edit/Delete + `-SubGroupCode` text |
| `SB/frm_Reports.cs` | Account Code section load SQL; `MergeIdSelections`; FilterAcctGroup/FilterAccount merge |
| `SB/frm_Reports.Designer.cs` | `msGroupCode`, `msAccountCode`, section labels/layout (Account Info အပေါ်) |
| `SB/MultiSelect.cs` (+ Designer if needed) | Selected display / AllSelectedText helpers — SB2 နောက်ကျနေရင် sync |

### အဆင့် ၃ — SQL (SB2 database)

`USE [SB1]` ရှိရင် **SB2 DB name** ပြင်ပါ။ အစဉ်အတိုင်း:

1. `docs/sql/AccountName_AcctCode.sql`  
   - `AccountName.AccountCode` column  
   - legacy `AcctCode` ရှိရင် sync  
   - `ListviewItem` MenuName=`Account`: **Account Code** column before Short  

2. `docs/sql/AcctGroup_GroupCode.sql` — `AcctGroup.GroupCode`  

3. `docs/sql/AcctSubGroup_SubGroupCode.sql` — `AcctSubGroup.SubGroupCode`  

Verify:

```sql
SELECT COL_LENGTH(N'dbo.AccountName', N'AccountCode') AS HasAccountCode;
SELECT COL_LENGTH(N'dbo.AcctGroup', N'GroupCode') AS HasGroupCode;
SELECT COL_LENGTH(N'dbo.AcctSubGroup', N'SubGroupCode') AS HasSubGroupCode;

SELECT ID, MenuName, ColumnName, ColumnWidth, ColumnHeader
FROM dbo.ListviewItem
WHERE MenuName = N'Account'
ORDER BY ID;
```

### အဆင့် ၄ — Rebuild + cache

- SB2 rebuild  
- App **restart** (သို့ `ReferenceDataCache` clear) — `ListviewItem` reload အတွက်

### အဆင့် ၅ — Smoke test

**Setup**

- [ ] Accounts: Account Code field Short အပေါ်; save; list မှာ Account Code column Short မတိုင်မီ  
- [ ] Account Group: Account Code → `GroupCode`; list Account Code column ပြ  
- [ ] Accounts / Account Group **tree**: SubGroup node (`B…`) right-click → New / Edit / Delete; node text မှာ `-SubGroupCode` (set ထားရင်)

**Reports**

- [ ] Account Code section Account Info **အပေါ်**  
- [ ] Group Code / Account Code lists = code (သို့ Short fallback) + `-` + Name  
- [ ] Account Info lists = **Short-Name only**  
- [ ] Code သို့ Info ကနေ select → merge → GL Detail စသည့် report filter (SP multi-filter ရှိမှ အပြည့်)

---

## Prompt for SB2 cloud agent (copy/paste)

```
SB ရဲ့ Account Code Setup + Reports Account Code / Account Info filter work ကို SB2 မှာ port လုပ်ပါ။

Reference PR: https://github.com/Nanda-MND/SB/pull/1
Branch: cursor/cheque-print-and-balance-filters
Checklist: docs/SB2_AccountCode_Port.md (SB repo)

Setup:
1. AccountName — Account Code textbox (Short အပေါ်) bind AccountName.AccountCode; listview Account Code before Short
2. AcctGroup — Account Code bind AcctGroup.GroupCode; list AccountCode = GroupCode (MenuName Account shared)
3. AcctSubGroup — LocalData.mySetup.AcctSubGroup = 20; Setup Detail Account Code = SubGroupCode; tree New/Edit/Delete (tag B+ID); tree text Name - [Short]-SubGroupCode

Reports:
4. Account Code section (Group Code + Account Code) above Account Info
5. Account Info lists = Short + '-' + Name only
6. Account Code lists = ISNULL(NULLIF(GroupCode/AccountCode,''), Short) + '-' + Name
7. Merge selections into FilterAcctGroup / FilterAccount (MergeIdSelections)

SQL (SB docs/sql — USE ကို SB2 DB name ပြင်):
- AccountName_AcctCode.sql
- AcctGroup_GroupCode.sql
- AcctSubGroup_SubGroupCode.sql

လက်ရှိ SB2 branch ပေါ်မှာ ဆက်လုပ်ပါ။ File-by-file merge လုပ်ပါ။ Rebuild + smoke test Setup Accounts/Group/SubGroup + Reports filters.
GL multi-filter SPs (AccountFilter_Helper / GL_AccountMultiFilter_Patch) ဒီ port ထဲမပါ — UI merge ပြီးမှ သီးခြား လုပ်နိုင်။
```

---

## Related (optional နောက်ဆက်)

| Doc | When |
|-----|------|
| `docs/Reports_AccountMultiFilter.md` | Report SP ဘက် `@Account` / `@AcctGroup` multi-filter လိုရင် |
| `docs/SB2_BankCharges_Port.md` | Bank Charges သီးခြား port |
