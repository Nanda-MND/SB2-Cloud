# SB2-Cloud — History ListView UX port (detailed)

Port **all** Main/history ListView improvements from SB into **SB2-Cloud** (Dev PC + Test Cloud first).  
This is **UI/app + ListviewItem SQL**, not SyncAgent. Still do **not** touch Live/Client until Dev acceptance passes.

## Why this is required

SB Main history (`dlvHistory` / FastObjectListView) was upgraded for:

| Feature | What it does |
|---------|----------------|
| **Footer summary** | StatusStrip totals: Total Amount, Paid, PK, Bank Charges, Income/Expense, etc. Spring spacer keeps totals visible |
| **Progress bar** | `tspbHistoryLoad` during `FillListView` (0→100) |
| **Multi-select** | Allow selecting multiple history rows (enable `MultiSelect`; wire batch-safe edit/delete/print where applicable) |
| **Column width / format** | `ListviewItem` widths + app overrides (Sales Car/Discount/Charges/Paid/PK); cashbook & balance layouts; numeric `#,#00` style |
| **Fast bind / menu switch** | `FastListViewHelper` + ObjectListView — fast menu change, in-memory balance sort |
| **Charges column** | Sales history Charges between Discount and Amount |

## Source files in SB (copy into SB2-Cloud)

### Must copy / port

| Path | Role |
|------|------|
| `SB/FastListViewHelper.cs` | **Critical.** Shared helper (`Configure`, `BindObjectTable`, cashbook/balance defaults, `SumNumericColumn`, selection helpers). If missing in a clone, recover from a machine that builds SB, then commit into SB2-Cloud. |
| `SB/frm_Main.cs` | `ConfigureHistoryListView`, `BindHistoryListView`, progress helpers, footer switch on menu, Sales width/Charges helpers, selection via helper |
| `SB/frm_Main.Designer.cs` | `dlvHistory` (ObjectListView), `statusStrip1`, `tspbHistoryLoad`, footer labels (`tslbMachine`, `tsLabelPaid`, `tsLablePK`, `tslbBankCharges`, Spring label) |
| `SB/frm_List.cs` (+ Designer) | Popup list uses same helper |
| `SB/frm_Setup.cs` / `frm_CodeList.cs` | Other ObjectListView binds using helper |
| `SB/SB.csproj` | Reference `ObjectListView.dll` (fix HintPath for SB2-Cloud; prefer `packages/` or `lib/ObjectListView.dll` in-repo) |
| `docs/sql/Sales_Listview_NarrowCarDiscount.sql` | Dev Local (+ Test Cloud after restore) `ListviewItem` width updates for Sales |

### Related docs

- `docs/SB2_BankCharges_Port.md` — SaleHistory Charges + Bank Charges footer + Spring
- `docs/MAIN_FORM_FILTER_CACHE_REFRESH.md` — do not regress filter/cache while porting ListView

## Implementation checklist (agent must complete)

### A. Dependencies
- [ ] `ObjectListView.dll` referenced and loads on Dev PC
- [ ] `FastListViewHelper.cs` present in project and compiles
- [ ] `dlvHistory` type is FastObjectListView / ObjectListView (not plain ListView)

### B. Progress bar
- [ ] `tspbHistoryLoad` on Main status strip
- [ ] `BeginHistoryLoadProgress` / `SetHistoryLoadProgress` / `EndHistoryLoadProgress` called around history fill
- [ ] Hidden when idle; continuous style

### C. Footer summary
- [ ] Status labels for: Total Amount, Paid Amount, PK, Bank Charges (Sales), Income/Expense where menus need them
- [ ] Menu `switch` updates footer from bound `DataTable` (use `FastListViewHelper.SumNumericColumn` where SB does)
- [ ] `toolStripStatusLabel` **Spring = true** so right-side totals stay visible on wide screens
- [ ] Clear/hide irrelevant labels when switching menus

### D. Multi-select
- [ ] `dlvHistory.MultiSelect = true` (via Designer and/or `FastListViewHelper.Configure`)
- [ ] Selection helpers (`HasSelection`, `TryGetSelectedId`, multi-id helpers if batch ops exist)
- [ ] Edit/Delete/Print: define behavior with 0 / 1 / N rows selected (match SB product rules; do not crash on multi)
- [ ] Visual: FullRowSelect, consistent highlight

### E. Column width & format
- [ ] Bind columns from `ListviewItem` / `ReferenceDataCache.ListViewColumns(menuName)`
- [ ] Sales: ensure Charges column; tighten Car/Discount/Charges/Paid/PK widths (config + `ApplySalesHistoryColumnWidths`)
- [ ] Run `Sales_Listview_NarrowCarDiscount.sql` on **Dev Local** (and Test Cloud after restore if ListviewItem is synced or restored)
- [ ] Cashbook layout defaults (`ApplyCashbookListDefaults`)
- [ ] Balance layout defaults (`ApplyBalanceListDefaults`) + in-memory sort
- [ ] Numeric columns readable format (thousands separators); date columns consistent
- [ ] PK / flag columns narrow; no horizontal clip of Amount/Charges on 1366px-class screens

### F. Performance / UX
- [ ] `PrepareForLayoutChange` / generation guard so stale async fills do not bind wrong menu
- [ ] Filter typing combos still work (`DropDown` style) without regressing ListView bind
- [ ] Menu switch feels fast (no full grid recreate when layout cache allows)

## How Tester opens it

1. Pull `cursor/sb2-dev-test-bootstrap-9fc4`.
2. Open `SB.sln`. Startup project is `SB`.
3. F5. Use menus Sales, Cashbook, and Balance.
4. Do not copy `SB2-git` `Bin\Debug` over `SB\bin\Debug`.
5. Mark H1–H8 only after that window is used. Code inspection is not PASS.

## Dev / Test verification (add to `SB2_DEV_TEST_RESULTS`)

| # | Test | Expect |
|---|------|--------|
| H1 | Open Sales history | Progress bar shows then hides; rows bind |
| H2 | Footer | Total / Paid / PK / Bank Charges correct vs data |
| H3 | Resize Main | Footer totals still visible (Spring) |
| H4 | Multi-select | Ctrl/Shift select multiple rows; UI stable |
| H5 | Sales columns | Charges visible; Car/Discount narrow; Amount not crushed |
| H6 | Balance menu | Sort/layout OK; Total Closing footer OK |
| H7 | Cashbook menu | Cashbook column defaults applied |
| H8 | Switch menus rapidly | No wrong columns / no crash / progress ends cleanly |

## Environment lock (same as sync port)

- Repo: **SB2-Cloud** only  
- Machine: **Dev PC**  
- DB: **Dev Local** (+ Test Cloud for SQL `ListviewItem` if restored)  
- Forbidden: Live DB, Client PC until Dev checklist PASS  

## Agent instruction snippet (append to main prompt)

```text
Also port the full History ListView UX pack from SB (see docs/SB2_HistoryListView_Port.md):
footer summary (status strip + Spring), tspbHistoryLoad progress bar, MultiSelect,
column width/format (ListviewItem + Sales Charges/narrow columns, cashbook/balance defaults),
and FastListViewHelper + ObjectListView. Recover FastListViewHelper.cs if missing.
Verify on Dev PC with the H1–H8 checklist; do not deploy to Client/Live yet.
```
