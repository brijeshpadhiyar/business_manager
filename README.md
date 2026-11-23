# StitchFlow (`સ્ટિચફ્લો`) — From Fabric to Finished.

An **offline-first, multi-platform Flutter Garment & Production Management System**. Built with **Android as the primary target** and full cross-platform support for iOS, Web, Windows, macOS, and Linux from a single Flutter codebase.

> **Project Phase:** **Complete V1 Production-Ready Release (Milestones 1–10 + Premium UI/UX Transformation)** — Verified & Tested.

---

## Core Capabilities

- **Lot, Design & Colour Management:** Unique lots with photos, nested designs, and colour-wise quantities and prices.
- **Quantity-Based Inventory:** Append-only stock ledger tracking physical in-house good stock, damaged stock bucket, lost/shortage settlements, and per-process pending balances.
- **Dynamic Production Processes:** Fully user-defined processes (e.g., Cutting, Press, Stitching, Finishing, Packing) with zero hardcoded sequence.
- **Workers / Members & Historical Pricing:** Many-to-many member-to-process assignments with effective-dated historical rates resolved by `transactionAt` in `Asia/Kolkata` and locked on stock issue.
- **Stock Movements & Partial Returns:** Multi-process stock flow, multiple partial returns, separate Good/Damaged/Lost/Shortage settlements, and strict over-issue / over-return prevention.
- **Configurable Labour & Member Ledger:** Default *Pay on Received Good Quantity* (configurable globally & per-process, optional damaged inclusion), anti-double-counting invariants, advance payments, negative balances (advance credit), and complete date-wise ledgers.
- **Audit Trail & Offline Backup:** UTC timestamps displayed in `Asia/Kolkata`, immutable history, raw `.sqlite` export for external viewers, and full unencrypted `.zip` backup/restore (DB + photos + attachments + manifest).
- **Bilingual & Adaptive UI:** English (`Business Manager`) & Gujarati (`બિઝનેસ મેનેજર`) via official `gen-l10n`, System/Light/Dark Material 3 theme, and responsive Mobile/Tablet/Desktop layouts.

---

## Technology Stack (Verified for Flutter 3.50.1 / Dart 3.14.0)

- **Framework:** Flutter `3.50.1` (stable) / Dart `3.14.0`
- **UI Foundation:** `material_ui` (`^1.11.1`, official decoupled Flutter Material 3 library by `flutter.dev`) + centralized `lib/core/widgets/`
- **Architecture:** Feature-first Clean Architecture (`presentation` → `domain` → `data`)
- **State Management:** `flutter_bloc` (`^9.1.1`)
- **Local Database:** `drift` (`^2.35.3`) + `drift_flutter` (`^0.3.1`) + `sqlite3` (`^3.9.1`, native build hooks; Web via `sqlite3.wasm` OPFS/IndexedDB)
- **Navigation:** `go_router` (`^18.1.4`)
- **DI & Codegen:** `get_it` (`^8.0.2`), `injectable` (`^3.0.0`), `freezed` (`^4.0.2`), `json_serializable` (`^6.15.2`)
- **Localization:** Flutter `gen-l10n` (`flutter_localizations` + `intl ^0.20.3`) + bundled Noto Sans Gujarati

---

## Documentation Index

| # | Document | Purpose |
| :-: | :--- | :--- |
| 00 | [docs/00_project_overview.md](docs/00_project_overview.md) | Vision, domain overview, scope, non-goals, glossary |
| 01 | [docs/01_business_requirements.md](docs/01_business_requirements.md) | Confirmed V1 business rules for all modules |
| 02 | [docs/02_functional_requirements.md](docs/02_functional_requirements.md) | Numbered functional requirements (`FR-001`+) |
| 03 | [docs/03_non_functional_requirements.md](docs/03_non_functional_requirements.md) | Performance, reliability, security, a11y, i18n |
| 04 | [docs/04_technology_stack.md](docs/04_technology_stack.md) | Verified packages, versions, official URLs, compatibility |
| 05 | [docs/05_system_architecture.md](docs/05_system_architecture.md) | Feature-first Clean Architecture & layer boundaries |
| 06 | [docs/06_folder_structure.md](docs/06_folder_structure.md) | Complete project folder tree & ownership rules |
| 07 | [docs/07_database_schema.md](docs/07_database_schema.md) | Drift/SQLite tables, types, constraints & indexes |
| 08 | [docs/08_database_relationships.md](docs/08_database_relationships.md) | Mermaid ERD, cardinality, soft-delete integrity |
| 09 | [docs/09_stock_calculation_rules.md](docs/09_stock_calculation_rules.md) | Physical stock, multi-process flow, damaged/lost/shortage |
| 10 | [docs/10_labour_calculation_rules.md](docs/10_labour_calculation_rules.md) | Billing modes, damaged eligibility, advances & ledger |
| 11 | [docs/11_member_pricing_rules.md](docs/11_member_pricing_rules.md) | Historical effective dates, IST lookup & rate lock |
| 12 | [docs/12_datetime_audit_strategy.md](docs/12_datetime_audit_strategy.md) | UTC storage, `Asia/Kolkata` display, audit logs |
| 13 | [docs/13_offline_storage_strategy.md](docs/13_offline_storage_strategy.md) | Private app storage, Web WASM OPFS/IDB, media layout |
| 14 | [docs/14_backup_restore_strategy.md](docs/14_backup_restore_strategy.md) | Raw `.sqlite` export, `.zip` backup/restore, security |
| 15 | [docs/15_design_system.md](docs/15_design_system.md) | Material 3 tokens, typography, System/Light/Dark themes |
| 16 | [docs/16_common_widget_guidelines.md](docs/16_common_widget_guidelines.md) | Centralized widget library APIs & guidelines |
| 17 | [docs/17_localization_strategy.md](docs/17_localization_strategy.md) | `gen-l10n`, EN/GU ARB rules, Noto Sans Gujarati |
| 18 | [docs/18_flavor_configuration.md](docs/18_flavor_configuration.md) | `dev` & `prod` flavors across Android, iOS, Web, Desktop |
| 19 | [docs/19_responsive_ui_strategy.md](docs/19_responsive_ui_strategy.md) | Android-first responsive navigation, forms & tables |
| 20 | [docs/20_testing_strategy.md](docs/20_testing_strategy.md) | Unit, DB migration, BLoC, widget & integration tests |
| 21 | [docs/21_implementation_roadmap.md](docs/21_implementation_roadmap.md) | Phased implementation sequence & milestones |
| 22 | [docs/22_technical_decisions.md](docs/22_technical_decisions.md) | Formal Architecture Decision Records (ADRs) |
| 23 | [docs/23_DOCUMENTATION_AUDIT_REPORT.md](docs/23_DOCUMENTATION_AUDIT_REPORT.md) | Complete documentation audit & readiness sign-off |
| 24 | [docs/24_FINAL_TECHNICAL_SAFEGUARDS.md](docs/24_FINAL_TECHNICAL_SAFEGUARDS.md) | Final technical safeguards (reversal guard, idempotency, WAL FULL) |
| 25 | [docs/25_MILESTONE_1_IMPLEMENTATION_REPORT.md](docs/25_MILESTONE_1_IMPLEMENTATION_REPORT.md) | Milestone 1 foundation implementation & validation report |
| 26 | [docs/26_MILESTONE_2_IMPLEMENTATION_REPORT.md](docs/26_MILESTONE_2_IMPLEMENTATION_REPORT.md) | Milestone 2 design system & common widgets report |
| 27 | [docs/27_MILESTONE_3_IMPLEMENTATION_REPORT.md](docs/27_MILESTONE_3_IMPLEMENTATION_REPORT.md) | Milestone 3 offline database core & media storage report |
| 28 | [docs/28_STITCHFLOW_BRAND_AND_APP_IDENTITY.md](docs/28_STITCHFLOW_BRAND_AND_APP_IDENTITY.md) | Official StitchFlow brand, logo, colors & identity spec |
| 29 | [docs/29_MILESTONE_3_5_IMPLEMENTATION_REPORT.md](docs/29_MILESTONE_3_5_IMPLEMENTATION_REPORT.md) | Milestone 3.5 branding & platform identity report |
| 30 | [docs/30_MILESTONE_4_IMPLEMENTATION_REPORT.md](docs/30_MILESTONE_4_IMPLEMENTATION_REPORT.md) | Milestone 4 business foundation (Modules A–F) report |
| 31 | [docs/31_STITCHFLOW_BUILD_AUTOMATION.md](docs/31_STITCHFLOW_BUILD_AUTOMATION.md) | One-command Windows APK build automation guide |
| 32 | [docs/32_MILESTONE_3_6_IMPLEMENTATION_REPORT.md](docs/32_MILESTONE_3_6_IMPLEMENTATION_REPORT.md) | Milestone 3.6 APK build automation report |
| 33 | [docs/33_MILESTONE_5_IMPLEMENTATION_REPORT.md](docs/33_MILESTONE_5_IMPLEMENTATION_REPORT.md) | Milestone 5 processes, workers & historical rates report |
| 34 | [docs/34_UI_UX_DESIGN_SYSTEM.md](docs/34_UI_UX_DESIGN_SYSTEM.md) | StitchFlow Premium Material 3 UI/UX design system & motion spec |
| 35 | [docs/35_MILESTONE_6_STOCK_MOVEMENTS_REPORT.md](docs/35_MILESTONE_6_STOCK_MOVEMENTS_REPORT.md) | Milestone 6 stock movements, settlements & reversal safeguards report |
| 36 | [docs/36_MILESTONE_7_LABOUR_AND_WORKER_ACCOUNTS_REPORT.md](docs/36_MILESTONE_7_LABOUR_AND_WORKER_ACCOUNTS_REPORT.md) | Milestone 7 labour calculation, worker ledger & payments report |
| 37 | [docs/37_MILESTONE_8_BACKUP_RESTORE_REPORT.md](docs/37_MILESTONE_8_BACKUP_RESTORE_REPORT.md) | Milestone 8 offline WAL-safe backup & atomic restore report |
| 38 | [docs/38_MILESTONE_9_DASHBOARD_REPORTS_REPORT.md](docs/38_MILESTONE_9_DASHBOARD_REPORTS_REPORT.md) | Milestone 9 live dashboard & 10 business reports report |
| 39 | [docs/39_MILESTONE_10_FINAL_QA_RELEASE_REPORT.md](docs/39_MILESTONE_10_FINAL_QA_RELEASE_REPORT.md) | Milestone 10 full QA, performance & release readiness report |

### Governance Files
- [CHANGELOG.md](CHANGELOG.md) — Version history and milestone tracking
- [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md) — Coding standards, codegen, and PR checklist
- [AGENT_RULES.md](AGENT_RULES.md) — Non-negotiable architectural and AI/developer rules

---

## One-Command Android APK Builds (Windows)

```powershell
# Development Release APK -> build/releases/dev/StitchFlow_Dev_YYYYMMDD_HHMMSS.apk
.\build_apk.bat dev

# Production Release APK -> build/releases/prod/StitchFlow_Prod_YYYYMMDD_HHMMSS.apk
.\build_apk.bat prod

# Optional Debug Builds
.\build_apk.bat dev debug
.\build_apk.bat prod debug
```

## Planned Flavor Commands (Post-Implementation)

```bash
# Android Development Flavor
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json

# Android Production Flavor
flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json
```
