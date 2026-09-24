# SB2-Cloud Dev / Test acceptance results

Fill this in the **SB2-Cloud** repo after Dev PC ↔ Test Cloud testing.  
Do not start Live/Client cutover until all required rows are PASS.

| # | Test | Expect | Result (PASS/FAIL) | Notes |
|---|------|--------|--------------------|-------|
| 1 | Environment | Only Dev Local + Test Cloud used | | |
| 2 | Repo | Work done in `SB2-Cloud`, not live SB | | |
| 3 | Local bootstrap | DataSync + Detail/Head packs + UserRights Local OK | | |
| 4 | Cloud restore | Dev `.bak` restored to Test Cloud | | |
| 5 | Cloud scripts | C2L + Detail/Head CLOUD + UserRights L2C-only | | |
| 6 | Agent `/once` | Dev↔Test Cloud cycle OK | | |
| 7 | Master L2C | Dev edit → Test Cloud | | |
| 8 | C2L (if enabled) | Test Cloud edit → Dev | | |
| 9 | Detail delete | Dev delete line → Test Cloud line gone | | |
| 10 | Head soft-delete | Dev soft-delete → Test Cloud stays deleted | | |
| 11 | UserRights | Dev change → Test Cloud; no C2L fight | | |
| 12 | Offline Dev | ERP works; outbox drains later | | |
| 13 | History progress | tspbHistoryLoad shows then hides on fill | | |
| 14 | History footer | Totals/Paid/PK/Bank Charges correct; Spring keeps totals visible | | |
| 15 | History MultiSelect | Ctrl/Shift multi-row select stable | | |
| 16 | History columns | Sales Charges + narrow Car/Discount; cashbook/balance layouts OK | | |
| 17 | History menu switch | Rapid menu change — no wrong columns / no crash | | |

**Sign-off (Dev/Test):** _________________ Date: _______

**Next (only after all PASS):** separate Live/Client cutover plan — ask before executing.
