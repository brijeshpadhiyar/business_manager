# 33 — Milestone 5 Implementation Report (StitchFlow Processes, Workers & Historical Rates)

**Completed Date:** 2026-11-23  
**SDK & Stack Verified:** Flutter `3.50.1` (`stable`) / Dart `3.14.0` / `material_ui: ^1.11.1` / `flutter_bloc: ^9.1.1` / `drift: ^2.35.3`  
**Milestone Scope:** Modules A–D (Dynamic Process Management, Worker Management, Many-to-Many Worker-Process Assignments, Historical Per-Piece Rates & Pure Dart `MemberProcessRateResolver`) wired into StitchFlow's `ResponsiveNavigation` shell. Zero schema changes (`schemaVersion = 1` preserved); strict boundaries maintained (no stock issue/return, damaged/lost stock, pending quantities, labour earnings, advances, or payments).

---

## 1. Modules Implemented

| Module | Scope Implemented | Key Safeguards |
| :--- | :--- | :--- |
| **A — Dynamic Process Management** | Create, edit, list, search, active/inactive filter & toggle, and detail view with assigned workers, timestamps (IST), and audit history. | Zero hardcoded processes or workflow sequence; case-insensitive active name uniqueness (`idx_processes_name_active`); atomic transactions + `CREATE`/`UPDATE`/`DEACTIVATE`/`REACTIVATE` audit logs. |
| **B — Worker Management** | Uses existing `members` table: create, edit, list, search (name/phone/address/notes), active/inactive filter & toggle, and Worker Profile Summary. | Validates required name; stores phone, address, notes; never physically deletes workers; omits labour earnings and payment balances per Milestone 5 boundaries. |
| **C — Worker-Process Assignment** | Many-to-many linkage via `member_processes`: assign multiple processes to a worker, multiple workers to a process, view both directions, deactivate/reactivate cleanly. | Rejects inactive workers, inactive processes, and duplicate active assignments; deactivating sets `is_active = 0` and re-assigning reactivates the existing pair row without violating `idx_member_processes_pair`. |
| **D — Historical Per-Piece Rates** | Configure effective-dated rates per Worker + Process in integer paise (`member_process_rates`), view current rate & full history, add new rates, and edit only when unreferenced by history. | Strict ISO `YYYY-MM-DD` validation; non-overlap & single-open-ended guards; confirmed atomic auto-close of previous open-ended rate (`newFrom - 1 day`); blocks edits if `stock_movements.source_rate_id` references the rate. |
| **Rate Lookup Domain Service** | Pure Dart `MemberProcessRateResolver` (zero Flutter/Drift imports). | Converts `transactionAt` UTC epoch ms to `Asia/Kolkata` (`IST`) calendar date (never uses `recordedAt`), resolves exact boundary dates, rejects missing or conflicting overlapping rates. |

---

## 2. Files Created & Modified

### Created Files
- **Processes (`lib/features/processes/`):**
  - `domain/entities/process_entities.dart` (+ `.freezed.dart`)
  - `domain/repositories/process_repository.dart`
  - `data/repositories/process_repository_impl.dart`
  - `presentation/bloc/{process_list_cubit.dart, process_detail_cubit.dart}` (+ `.freezed.dart`)
  - `presentation/pages/{process_list_page.dart, process_form_page.dart, process_detail_page.dart}`
- **Workers & Assignments (`lib/features/workers/`):**
  - `domain/entities/worker_entities.dart` (+ `.freezed.dart`)
  - `domain/repositories/worker_repository.dart`
  - `data/repositories/worker_repository_impl.dart`
  - `presentation/bloc/{worker_list_cubit.dart, worker_detail_cubit.dart, worker_assignments_cubit.dart}` (+ `.freezed.dart`)
  - `presentation/pages/{worker_list_page.dart, worker_form_page.dart, worker_detail_page.dart, worker_assignments_page.dart}`
- **Historical Rates & Resolver (`lib/features/rates/`):**
  - `domain/entities/rate_entities.dart` (+ `.freezed.dart`)
  - `domain/services/member_process_rate_resolver.dart` (100% pure Dart)
  - `domain/repositories/rate_repository.dart`
  - `data/repositories/rate_repository_impl.dart`
  - `presentation/bloc/rate_history_cubit.dart` (+ `.freezed.dart`)
  - `presentation/pages/{rate_history_page.dart, rate_form_page.dart}`
- **Tests:**
  - `test/features/member_process_rate_resolver_test.dart`
  - `test/features/processes_workers_rates_repository_test.dart`
  - `test/widget/milestone_5_ui_test.dart`

### Modified Files
- `lib/core/database/daos/process_member_dao.dart` (+ `.g.dart`) — Added list, search-support, update, assignment, and rate query/update methods (zero schema changes).
- `lib/core/database/daos/stock_movement_dao.dart` (+ `.g.dart`) — Added read-only `hasMovementsUsingRate(String rateId)` SELECT query while keeping DAO strictly append-only.
- `lib/core/error/exceptions.dart` — Added typed `DomainValidationException` with machine-readable error codes for clean localized UI mapping.
- `lib/core/router/{route_paths.dart, app_router.dart}` — Added `Processes` and `Workers` tabs to `StitchFlowShellPage` and registered routes for Process, Worker, Assignment, Rate History, and Rate Form pages.
- `lib/core/widgets/responsive_navigation.dart` — Made Tablet `NavigationRail` scrollable for 6 destinations on compact heights and wrapped Desktop `NavigationDrawer` labels in `Flexible` with ellipsis to eliminate horizontal overflow.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` — Added quick-action buttons for Processes and Workers and updated tab indices.
- `lib/l10n/{app_en.arb, app_gu.arb}` (+ generated `app_localizations*.dart`) — Added 88 bilingual EN/GU keys (`0` untranslated entries).
- `lib/core/di/injection.config.dart` — Regenerated DI registrations for all Milestone 5 repositories and Cubits.
- `CHANGELOG.md`, `README.md`, `docs/11_member_pricing_rules.md`.

---

## 3. Process, Worker, Assignment & Historical Rate Architecture

- **Process Architecture:** Fully dynamic rows in `processes` with optional `billing_mode_override` (`NULL` = inherit global, `RECEIVED_QTY`, `GIVEN_QTY`) and `include_damaged_in_labour`. No enum, switch statement, or sequence order is hardcoded anywhere.
- **Worker Management:** Uses `members` with soft activation (`is_active`) and non-destructive editing. `WorkerDetailPage` displays a focused Worker Profile Summary (name, phone, address, notes, active status, assigned processes, current IST-resolved per-piece rates, and rate history counts).
- **Assignment Implementation:** `member_processes` enforces unique `(member_id, process_id)` pairs with `ON DELETE RESTRICT`. Assigning validates both entities are active and non-deleted; removing sets `is_active = 0` with a `DEACTIVATE` audit log, and re-assigning reactivates the row with `REACTIVATE` audit log.
- **Historical Rate Logic & `MemberProcessRateResolver`:**
  - Rates are stored in integer paise (`rate_paise >= 0`) with inclusive IST dates `effective_from` and nullable `effective_to`.
  - Overlap check: $[s_1, e_1]$ overlaps $[s_2, e_2]$ iff $(e_2 = \infty \lor s_1 \le e_2) \land (e_1 = \infty \lor s_2 \le e_1)$.
  - Adding a new rate when an earlier open-ended rate exists prompts confirmation and—inside a single atomic `DatabaseTransactionRunner` transaction—closes the previous rate to `previousDayIso(newEffectiveFrom)` (`UPDATE` audit) and inserts the new rate (`CREATE` audit).
  - `MemberProcessRateResolver.resolve(workerId, processId, transactionAtUtcMillis, rates)` converts `transactionAtUtcMillis` to `Asia/Kolkata` (`YYYY-MM-DD`) via `IstDateTimeHelper.toIstBusinessDate` and returns a sealed `RateResolutionResult` (`RateResolutionFound`, `RateResolutionMissing`, or `RateResolutionConflict`).

---

## 4. Database Changes

- **None (`schemaVersion = 1` preserved).** All 4 tables (`processes`, `members`, `member_processes`, `member_process_rates`), foreign keys (`ON DELETE RESTRICT`), check constraints, and indexes (`idx_processes_name_active`, `idx_member_processes_pair`, `idx_rates_lookup`) from Milestone 3 already satisfied 100% of Milestone 5 requirements.

---

## 5. Validation & Build Results

| Command | Result |
| :--- | :--- |
| `flutter pub get` | **PASS** |
| `flutter gen-l10n` | **PASS** (`0` untranslated keys; `l10n_untranslated.txt` = `{}`) |
| `dart run build_runner build` | **PASS** (`335` outputs, exit code `0`) |
| `dart format .` | **PASS** |
| `flutter analyze` | **PASS** (`No issues found!`) |
| `flutter test` | **PASS** (`57 / 57` tests passed — 15 new Milestone 5 unit, repository, and responsive EN/GU Light/Dark widget tests + all 42 Milestone 1–4 tests) |
| `.\build_apk.bat dev debug` | **PASS** (`build\releases\dev\StitchFlow_Dev_20261123_130040_debug.apk`, `204.11 MB`) |

---

## 6. Known Issues & Pending Decisions

- **Physical Device / Emulator Note:** No Android emulator or USB device was attached in this CLI environment; verification covered all 57 automated unit/repository/widget tests (including 360dp mobile, 800dp tablet, and 1280dp desktop viewports) plus a full `dev` debug APK build. On-device smoke testing on Android is recommended before moving to Milestone 6.
- **Pending Approval:** Awaiting your review and approval of Milestone 5 before proceeding to **Milestone 6 (Stock Movements — Issue, Partial Returns, Damaged/Lost/Shortage Settlements & Pending Balances)**.
