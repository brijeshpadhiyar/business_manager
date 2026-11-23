# 20 — Testing Strategy

## 1. Test Pyramid & Tooling

| Layer | Tools | Scope & Target Coverage |
| :--- | :--- | :--- |
| **1. Pure Domain Unit Tests** | `flutter_test` | `StockCalculator`, `LabourCalculator`, `RateResolver`, `LedgerCalculator`, `IstDateTimeHelper`, `BackupValidator` (**>= 95% coverage**) |
| **2. Database & Migration Tests** | `drift` (`NativeDatabase.memory()`) | Foreign keys, unique/check constraints, atomic transactions, schema upgrades (`v1 -> v2 -> ...`), `VACUUM INTO` export & integrity check |
| **3. BLoC / Cubit Tests** | `bloc_test ^10.0.0`, `mocktail ^1.0.5` | State transitions, validation errors, loading/empty/error states, theme/locale persistence |
| **4. Widget & Localization Tests** | `flutter_test` | All 20 centralized `core/widgets/`, EN & GU rendering, Light & Dark theme, responsive breakpoints (`360dp`, `768dp`, `1280dp`), text scaling (`1.3x`) |
| **5. End-to-End Integration Tests** | `integration_test` (Android priority) | Full offline flows: Lot → Issue → Partial Return → Labour → Payment → Backup & Restore |

---

## 2. Mandatory Unit Test Scenarios for All 11 Confirmed Business Rules

Every confirmed V1 requirement **must** have automated tests before its feature milestone is marked complete:

### A. Multi-Process Stock Flow & Physical Cap (`StockCalculator`)
1. **Valid Multi-Process Flow:** `100` initial → issue `100` to *Cutting* (`PhysicalAvailableInHouse = 0`, `Cutting.pending = 100`) → return `80` Good from *Cutting* (`avail = 80`, `Cutting.pending = 20`) → issue `80` to *Stitching* (`avail = 0`, `Stitching.pending = 80`).
2. **Over-Issue Blocked:** With `avail = 0` (or `avail = 80`), attempting to issue `1` (or `81`) to any process throws `InsufficientPhysicalStockFailure`.
3. **Flexible Process Order:** Issuing directly to *Packing* or *Press* without ever running *Cutting* succeeds (zero hardcoded order).

### B. Damaged / Lost / Shortage Settlements (`StockCalculator`)
4. **Combined Settlement Closes Pending:** Issue `100` → settle `95 RETURN_GOOD` + `3 RETURN_DAMAGED` + `2 SETTLEMENT_LOST` → `ParentRemainingPending = 0`, `PhysicalAvailableInHouse = 95`, `DamagedBucket = 3`, `TotalLost = 2`.
5. **Damaged Never Added to Good Stock:** Verify `RETURN_DAMAGED` increments `DamagedBucket` and leaves `PhysicalAvailableInHouse` unchanged.
6. **Over-Settlement Blocked:** After settling `100`, attempting `1` more Good/Damaged/Lost/Shortage fails with `OverSettlementFailure`.
7. **Mandatory Reason Guard:** Submitting `RETURN_DAMAGED`, `SETTLEMENT_LOST`, or `SETTLEMENT_SHORTAGE` with empty `reason` fails validation.

### C. Damaged Stock Disposition & Authorized Repair Adjustment (`StockCalculator`)
8. **Authorized Repair Adjustment:** With `DamagedBucket = 3`, recording `ADJUSTMENT_DAMAGED_TO_GOOD(qty: 2, reason: "Repaired collar")` → `DamagedBucket = 1`, `PhysicalAvailableInHouse` increases by `+2`, and an `audit_logs` record (`DAMAGED_TO_GOOD_ADJUSTMENT`) is written.
9. **Over-Repair Blocked:** Attempting `ADJUSTMENT_DAMAGED_TO_GOOD(qty: 4)` when `DamagedBucket = 3` fails with `InsufficientDamagedStockFailure`.
10. **No Silent Conversion:** Attempting `ADJUSTMENT_DAMAGED_TO_GOOD` without a non-empty reason fails validation.

### D. Labour Billing Modes & Damaged Eligibility (`LabourCalculator`)
11. **Default Pay-on-Received Good Only:** Issue `100` at `₹20` (`RECEIVED_QTY`, `include_damaged_in_labour = false`) → settle `95 Good + 3 Damaged + 2 Lost` → `IssuedLabour = ₹2,000 (non-payable)`, `ReceivedLabour = ₹1,900 (payable)`, `EarnedLabour = ₹1,900`.
12. **Process Override Including Damaged:** Same settlement with process `include_damaged_in_labour = true` → `ReceivedGood = ₹1,900 (payable)` + `ReceivedDamaged = ₹60 (payable)` → `EarnedLabour = ₹1,960`. Lost (`2`) = `₹0`.
13. **Lost / Shortage Never Billed:** Verify `SETTLEMENT_LOST` and `SETTLEMENT_SHORTAGE` produce `₹0` labour under both `include_damaged_in_labour = false` and `true`.
14. **Process Override `GIVEN_QTY` Anti-Double-Count:** Issue `100` at `₹20` → `IssuedLabour = ₹2,000 (payable)`; return `80 Good` → `ReceivedLabour = ₹1,600 (non-payable)`; `EarnedLabour` stays `₹2,000`.
15. **Mid-Flight Config Change Lock:** Issue `100` under `RECEIVED_QTY`, return `40`, then change process default to `GIVEN_QTY`, then return remaining `60` → open issue stays locked to `RECEIVED_QTY` so total payable is `40 + 60 = 100` pcs (neither `40` nor `200`).

### E. Historical Pricing, IST Date Boundary & Partial Return Rate Lock (`RateResolver`)
16. **IST Midnight Boundary Lookup:** Rate `₹20` until `2026-11-30`, `₹30` from `2026-12-01`. `transactionAt = 2026-11-30T19:00:00Z` (`2026-12-01 00:30 IST`) resolves `₹30`; `2026-11-30T18:29:59Z` (`2026-11-30 23:59:59 IST`) resolves `₹20`.
17. **Backdated Transaction Lookup:** Entry recorded on `2026-12-05` (`recordedAt`) with `transactionAt = 2026-11-29 IST` resolves `₹20`.
18. **Partial Return Rate Lock:** Issue `100` on `2026-11-28` (`₹20`) → rate rises to `₹30` on `2026-12-01` → return `80` on `2026-12-05` → billed at locked `₹20` (`₹1,600`).
19. **Audited Manual Rate Override:** Return remaining `20` with confirmed override to `₹25` + reason → billed at `₹25` (`₹500`), `is_rate_overridden = true`, `audit_logs` records `2000 -> 2500`, and parent issue's locked rate stays `₹20`.
20. **Overlap Prevention:** Attempting to insert an overlapping date range for the same `(member_id, process_id)` fails validation.

### F. Advance Payments & Negative Balances (`LedgerCalculator`)
21. **Advance Credit & Auto-Offset:** Pay `₹1,000 ADVANCE` (`Outstanding = ₹0`, `AdvanceCredit = ₹1,000`) → earn `₹600` (`Outstanding = ₹0`, `AdvanceCredit = ₹400`) → earn `₹1,000` (`Outstanding = ₹600`, `AdvanceCredit = ₹0`) → pay `₹600 REGULAR` (`Outstanding = ₹0`, `AdvanceCredit = ₹0`).
22. **Advance Refund Settlement:** With `AdvanceCredit = ₹400`, record `₹400 ADVANCE_REFUND` → `AdvanceCredit = ₹0`, `Outstanding = ₹0`.

### G. Branding, `material_ui` Material 3, Reversals & Backup / Restore (`BackupValidator` & Widget Tests)
23. **Configurable Branding & Localization:** Verify default `Business Manager` (EN) and `બિઝનેસ મેનેજર` (GU) render properly and update when `business_profile` is edited.
24. **Raw `.sqlite` Export & Integrity:** Export via `VACUUM INTO`, reopen exported file with `sqlite3`, run `PRAGMA integrity_check` → returns `ok`.
25. **Full `.zip` Backup & Atomic Rollback:** Verify valid `.zip` restores DB + attachments cleanly; verify corrupted checksum `.zip` is rejected before touching live DB; verify simulated mid-restore failure rolls back automatically to pre-restore snapshot.
26. **Private Storage Guarantee:** Verify live DB path resolves strictly inside private application documents directory and never public external storage.
27. **Parent Issue Reversal Guard & Reversed Labour Exclusion:** Verify reversing an `ISSUE` with active child settlements is blocked; verify reversing a child `RETURN_GOOD` creates a linked `REVERSAL` labour entry (`reverses_labour_entry_id`) and cleanly deducts from `TotalReceivedLabour` and `EarnedLabour`, while blocking any second reversal via unique partial index.

### H. Final Technical Safeguards (`docs/24_FINAL_TECHNICAL_SAFEGUARDS.md`)
28. **Downstream Stock Reversal Blocked (`RETURN_GOOD`):** `100` initial → `100` Cutting issue → `80` Cutting good return → `80` Stitching issue → attempt to reverse the `80` Cutting good return → **REJECTED** with `DownstreamStockDependencyFailure` identifying the Stitching issue; verify zero downstream rows are mutated.
29. **Downstream Chronological Replay Guard (Even When Later Returned):** Same as #28 plus `80` Stitching return (current avail `80`) → attempt to reverse the `80` Cutting return → **REJECTED** because chronological replay at Stitching issue time goes negative (`-80`).
30. **Damaged-to-Good Reversal Dependency Guard:** `3` damaged → `ADJUSTMENT_DAMAGED_TO_GOOD(2)` → `ISSUE(2)` consumes them → attempt to reverse `ADJUSTMENT_DAMAGED_TO_GOOD(2)` → **REJECTED** with `DownstreamStockDependencyFailure`. Similarly, reversing `RETURN_DAMAGED(3)` after `ADJUSTMENT_DAMAGED_TO_GOOD(2)` → **REJECTED** (`DamagedBucket < 0`).
31. **Labour Entry Idempotency (DB Unique Constraint):** Attempting to insert a second `labour_entries` row with the same `(stock_movement_id, basis_type)` or same `reverses_labour_entry_id` fails at SQLite constraint level.
32. **Retry-Safe Submission (`client_request_id`):** Submitting the same stock movement or payment twice with identical `client_request_id` returns the original committed record idempotently with zero duplicate stock/labour/payment rows.
33. **Atomic 5-Point Pre-Issue Worker-Process Validation:** Attempting `ISSUE` when member is inactive, process is inactive, `member_processes` link is missing/inactive, no effective historical rate exists, or stock is insufficient → **REJECTED** atomically. Verify deactivating member/process afterward still allows viewing history and recording partial returns on already-open issues.
34. **SQLite WAL Durability & Snapshot Consistency:** Verify `PRAGMA journal_mode` returns `wal`, `PRAGMA synchronous` returns `2` (`FULL`), `PRAGMA foreign_keys` returns `1`, and `VACUUM INTO` snapshot created while WAL has active writes passes `PRAGMA integrity_check` with all committed rows present.
