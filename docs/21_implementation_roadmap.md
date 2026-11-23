# 21 — Implementation Roadmap

The application will be built incrementally across **8 milestones**, keeping Android runnable and tested at every stage without architectural rework.

---

## Milestone 1 — Foundation, Dependencies, Flavors & Governance
- Pin `material_ui: ^1.11.1` in `pubspec.yaml` (official decoupled Flutter Material 3 library by `flutter.dev`) and standardize on `package:material_ui/material_ui.dart`.
- Add verified V1 dependencies (`docs/04_technology_stack.md`) and bundle Noto Sans Gujarati fonts.
- Configure `l10n.yaml`, `app_en.arb`, `app_gu.arb` with initial core strings (`Business Manager` / `બિઝનેસ મેનેજર`).
- Configure `dev` & `prod` flavors (`android/app/build.gradle.kts`, `config/dev.json`, `config/prod.json`, `lib/main_dev.dart`, `lib/main_prod.dart`).
- Set up `get_it` + `injectable`, `go_router`, `IstDateTimeHelper`, `MoneyFormatter`, and `IdGenerator`.
- **Exit Criteria:** Both `dev` and `prod` APKs build and install side-by-side on Android with isolated storage.

## Milestone 2 — Material 3 Design System & Centralized Widget Library
- Implement `AppColors`, `AppSemanticColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppSizing`, and `AppTheme` (System/Light/Dark + `ThemeCubit` + `LocaleCubit`).
- Implement all 20 centralized components in `lib/core/widgets/` (`docs/16_common_widget_guidelines.md`), including `AdaptiveShellScaffold` and `AppDataTable`.
- **Exit Criteria:** Widget tests pass in Light/Dark themes and EN/GU locales across `360dp`, `768dp`, and `1280dp` viewports.

## Milestone 3 — Offline Database Core (Drift + SQLite)
- Implement all 13 Drift tables, constraints, partial unique indexes, DAOs, `PRAGMA` setup, and cross-platform connections (`native` + `web` WASM assets).
- Seed default `business_profile` (`Business Manager` / `બિઝનેસ મેનેજર`, `default_billing_mode = RECEIVED_QTY`).
- Implement `AuditLogService` and local private `MediaService` (photo compression + SHA-256).
- **Exit Criteria:** All in-memory Drift integrity, FK, and migration tests pass.

## Milestone 4 — Master Data Modules (Processes, Members, Pricing, Lots)
- Build **Dynamic Processes** CRUD (activate/deactivate, billing mode override, `include_damaged_in_labour` toggle).
- Build **Members** CRUD + many-to-many Process assignment + **Historical Member Pricing** (`RateResolver` + overlap guard + auto-close previous rate).
- Build **Lots → Designs → Colours** CRUD + multi-photo attachment viewer.
- **Exit Criteria:** Full master data flows work offline on Android with complete audit logging.

## Milestone 5 — Stock Movements, Partial Returns & Damaged Adjustments
- Implement pure Dart `StockCalculator` with full unit test suite.
- Build **Issue Stock** flow (physical stock validation, `transactionAt` IST rate lookup & lock, locked billing mode).
- Build **Partial Return & Settlement** flow (`RETURN_GOOD`, `RETURN_DAMAGED`, `SETTLEMENT_LOST`, `SETTLEMENT_SHORTAGE`, inherited locked rate, audited manual rate override).
- Build **Authorized Damaged-to-Good Repair Adjustment** & **Reversal** workflows.
- **Exit Criteria:** All multi-process, over-issue, over-return, rate-lock, and damaged-bucket unit & DB tests pass.

## Milestone 6 — Labour Calculation, Payments & Member Ledger
- Implement pure Dart `LabourCalculator` and `LedgerCalculator` with full unit test suite.
- Build **Payments** (`REGULAR`, `ADVANCE`, `ADVANCE_REFUND`, `REVERSAL` + receipt attachments).
- Build **Member Ledger** screen (quantity summary, process-wise breakdown, rate history, Earned/Paid/Outstanding Payable/Advance Credit, chronological timeline).
- **Exit Criteria:** Zero double-counting verified across all billing modes and advance credit lifecycles.

## Milestone 7 — Dashboard, Reports & Backup / Restore
- Build **Dashboard** (live KPIs: Active Lots, Pending Pieces, Damaged Bucket, Total Payable, Total Advance Credit).
- Build all 5 **Reports** (Lot Summary, Process Workload, Worker Pending & Payable, Damaged/Lost/Shortage, Payment Cashflow).
- Build **Settings & Business Profile** editor + **Raw `.sqlite` Export** (`VACUUM INTO`) + **Full `.zip` Backup & Atomic Restore** (`BackupValidator` + rollback).
- **Exit Criteria:** End-to-end Android backup → wipe → restore test restores 100% of DB rows and photos.

## Milestone 8 — Multi-Platform Polish & Release Hardening
- Verify Tablet (`NavigationRail`) and Desktop (`Sidebar` + `DataTable`) layouts on Windows/Web/iOS/macOS/Linux.
- Verify Web SQLite WASM (`sqlite3.wasm` + `drift_worker.js`) persistence banner and browser download/upload backup.
- Run full `flutter analyze`, full test suite, and release APK smoke testing on physical Android device.

---

## Recommended First Implementation Task

**Task 1.1 (Milestone 1 Kickoff):** Update `pubspec.yaml` (pin `material_ui: ^1.11.1`, add verified V1 dependencies and Noto Sans Gujarati font assets), configure `l10n.yaml` + `app_en.arb`/`app_gu.arb`, and set up `dev`/`prod` flavor configurations in `android/app/build.gradle.kts` and `lib/core/config/`.
