# StitchFlow — Technical Architecture, Database & Web Readiness Audit

**Audit Date:** 2026-11-24  
**Tech Stack:** Flutter + Dart SDK `^3.14.0`, `material_ui: ^1.11.1`, `flutter_bloc: ^9.1.1`, `drift: ^2.35.3` + `drift_flutter: ^0.3.1` + `sqlite3: ^3.9.1`, `go_router: ^18.1.4`, `get_it: ^9.3.0` + `injectable: ^3.0.0`, `freezed_annotation: ^3.1.0`, `excel_plus: ^2.29.3`.

---

## 1. Architecture & Clean Layer Separation

- **Zero Violations of `AGENT_RULES.md`:**
  - 100% offline local SQLite via Drift (no REST/Firebase/Supabase/online auth).
  - Zero hardcoded production processes or worker rates.
  - Pure Dart domain calculators (`StockCalculator`, `LabourCalculator`, `LedgerCalculator`, `ProductionHistoryCalculator`, `MemberProcessRateResolver`, `ReportAnalyticsCalculator`) cleanly separated from BLoCs/Cubits and UI.
  - 28 Cubits, 11 Repositories, 11 Drift DAOs.

---

## 2. Database Schema & Query Performance Audit (Schema v8)

- **Schema Version:** `v8` (incremental non-destructive migrations `v1 → v8`).
- **Tables:** `business_profile`, `lots`, `lot_designs`, `design_colours`, `colour_master`, `processes`, `members`, `member_processes`, `member_process_rates`, `job_processes`, `process_handovers`, `process_additional_charges`, `process_rate_history`, `stock_movements`, `production_returns`, `production_inspections`, `rejection_records`, `rejection_repairs`, `labour_entries`, `payments`, `worker_ledger_adjustments`, `attachments`, `audit_logs`.
- **Indexes:** 44 indexes across `v1IndexStatements..v8IndexStatements` in `schema_indexes.dart`, covering active lot lookups, design/colour uniqueness, rate effective ranges, stock movements by lot/design_colour/parent_issue/member/process/job_process/date, single-reversal unique guards, `client_request_id` idempotency guards, and all Schema v8 return/inspection/rejection/repair foreign keys.
- **Query Audit Findings:**
  1. `production_history_repository_impl.dart` & `reports_repository_impl.dart` perform bulk reads and in-memory indexed map joins (`O(N)`), avoiding per-row N+1 queries. We will add an automated SQLite `EXPLAIN QUERY PLAN` + 500-movement benchmark test in Phase 5/6 to prove zero unindexed hot-path scans and verify sub-150ms reconciliation timings.
  2. `lot_dao.dart` needs lightweight read/search methods for the unified **Designs & Colours** view (aggregating `lot_designs` + `design_colours` + `lots` in a single query without N+1 loops).
  3. Schema stays at **v8** (no unnecessary schema bump or migration risk).

---

## 3. Flutter Web Blockers Audit (Exact 7 Files)

Running a full repository scan for `dart:io` and `dart:isolate` identified **exactly 7 files** preventing `flutter build web` compilation or runtime operation:

| # | File | Blocking Import / API | Planned Resolution (Phase 5) |
|---|---|---|---|
| 1 | `lib/features/backup/data/services/native_backup_restore_service.dart` | `dart:io`, `archive_io.dart`, `drift/native.dart`, `sqlite3/sqlite3.dart` | Split behind `backup_restore_service_factory.dart` (conditional export: `NativeBackupRestoreService` on IO, `WebBackupRestoreService` on Web with JSON/snapshot export + verified transactional restore). |
| 2 | `lib/features/reports/data/services/excel_csv_export_service.dart` | `dart:io`, `dart:isolate` (`Isolate.run`), `path_provider`, `share_plus` | Extract platform delivery helper (`report_export_platform_native.dart` vs `report_export_platform_web.dart`): Web uses browser Blob downloads for `.xlsx`/`.csv` and HTML print window (`window.print()`) for PDF/Print; Native keeps Isolate + Android `PrintManager` + `share_plus`. |
| 3 | `lib/features/security/domain/services/pin_hasher.dart` | `dart:isolate` (`Isolate.run`) | Conditional runner (`pin_hasher_runner_native.dart` uses `Isolate.run`; `pin_hasher_runner_web.dart` executes directly on Web). |
| 4 | `lib/features/notifications/data/services/flutter_local_notifications_adapter.dart` | `dart:io` (`Platform.isAndroid`, etc.) | Replace `dart:io` `Platform` checks with `kIsWeb` + `defaultTargetPlatform` (`package:flutter/foundation.dart`). |
| 5 | `lib/features/security/data/repositories/secure_storage_security_repository.dart` | `dart:io show Platform` | Replace `Platform` check with `kIsWeb` + `defaultTargetPlatform`. |
| 6 | `lib/features/security/data/services/local_auth_biometric_service.dart` | `dart:io show Platform` | Replace `Platform` check with `kIsWeb` + `defaultTargetPlatform` (returns unavailable cleanly on Web). |
| 7 | `web/` runtime assets | Missing `web/sqlite3.wasm` & `web/drift_worker.js` required by `database_connection_web.dart` | Bundle verified matching `sqlite3.wasm` and `drift_worker.js` in `web/` so `drift_flutter` initializes SQLite WASM (OPFS/IndexedDB) offline on Chrome. |

---

## 4. Automated Test Suite Audit

- **Existing Test Files:** 43 test files across `test/database/`, `test/features/`, `test/unit/`, and `test/widget/`.
- **Known Gaps to Close in Phase 6:**
  1. Legacy billing assertions in `test/features/labour_and_ledger_calculator_test.dart` & `test/features/end_to_end_business_workflow_test.dart` need updating to assert the finalized **Accepted-Only** earnings rule (proving legacy flags cannot alter new earnings).
  2. Add dedicated Schema v8 test suites (`production_history_calculator_test.dart`, `schema_v8_production_history_migration_test.dart`, `production_history_workflow_test.dart`).
  3. Add 9-viewport **Responsive Matrix Widget Tests** (`360..1920px` + live resize).
  4. Add 19-step **Master Workflow Regression Test** + Backup/Restore verification + Performance Benchmark test (`500+` movements).
