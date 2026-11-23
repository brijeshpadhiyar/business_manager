# 30 — Milestone 4 Implementation Report (StitchFlow Business Foundation)

**Completed Date:** 2026-11-23  
**SDK & Stack Verified:** Flutter `3.50.1` (`stable`) / Dart `3.14.0` / `material_ui: ^1.11.1` / `flutter_bloc: ^9.1.1` / `drift: ^2.35.3`  
**Milestone Scope:** Modules A–F (Business Profile, Lot Management, Lot Photos, Design Management, independent Colour Management, and read-only Initial Inventory Overview) wired into StitchFlow's `ResponsiveNavigation` shell. Zero schema changes (`schemaVersion = 1` preserved), zero Milestone 5+ modules (Processes, Workers, Rates, Stock Movements, Labour, Payments).

---

## 1. Modules Implemented

| Module | Scope Implemented | Key Safeguards |
| :--- | :--- | :--- |
| **A — Business Profile** | View & edit singleton `business_profile` (`nameEn`, `nameGu`, `ownerName`, `phone`, `address`, `defaultBillingMode`), distinct from StitchFlow app name. | Atomic transaction + `UPDATE` audit log; never auto-overwrites existing workshop name; rejects blank names. |
| **B — Lot Management** | Create, list, search, status-filter (`All`/`Active`/`Completed`), detail view, edit, and archive (soft delete) lots. | Active `lot_number` uniqueness (`idx_lots_number_active`); zero physical deletion; full `audit_logs`. |
| **C — Lot Photos** | Camera & gallery capture (`image_picker` with `maxWidth: 1600`, `maxHeight: 1600`, `imageQuality: 80`), multiple photos per lot, zoomable preview, soft-delete removal. | Private storage via `MediaStorageService`, SHA-256 checksums in `attachments`, graceful missing-file UI, **automatic orphan-file cleanup** if DB transaction fails. |
| **D — Design Management** | Create, edit, search/filter, and archive multiple designs inside a lot (`lot_designs`). | FK `lot_id` validation; case-insensitive active uniqueness (`idx_lot_designs_unique`); `audit_logs`. |
| **E — Colour Management** | Add, edit, and archive multiple colours per design (`design_colours`) with independent `initialQuantity` (`> 0`) and `unitPricePaise` (`>= 0`, INR formatted). | Never merges colour quantities/prices; case-insensitive active uniqueness (`idx_design_colours_unique`); `audit_logs`. |
| **F — Initial Inventory Overview** | Read-only pure Dart `InventoryOverviewCalculator` displaying Active Lots, Designs, Design+Colour count, Total **Initial Quantity**, and Lot/Design/Colour tables. | Explicitly labeled *Initial Quantity* (never claims post-movement available stock); excludes archived lots/designs. |

---

## 2. Files Created & Modified

### Created Files
- **Business Profile (`lib/features/business_profile/`):**
  - `domain/entities/business_profile_entity.dart` (+ `.freezed.dart`)
  - `domain/repositories/business_profile_repository.dart`
  - `data/repositories/business_profile_repository_impl.dart`
  - `presentation/bloc/{business_profile_state.dart, business_profile_cubit.dart}` (+ `.freezed.dart`)
  - `presentation/pages/business_profile_page.dart`
- **Lots, Designs, Colours & Photos (`lib/features/lots/`):**
  - `domain/entities/lot_entities.dart` (+ `.freezed.dart`)
  - `domain/repositories/lot_repository.dart`
  - `data/repositories/lot_repository_impl.dart`
  - `presentation/bloc/{lot_list_cubit.dart, lot_detail_cubit.dart}` (+ `.freezed.dart`)
  - `presentation/pages/{lot_list_page.dart, lot_detail_page.dart}`
- **Inventory Overview (`lib/features/inventory/`):**
  - `domain/calculators/inventory_overview_calculator.dart` (100% pure Dart)
  - `presentation/bloc/inventory_overview_cubit.dart` (+ `.freezed.dart`)
  - `presentation/pages/inventory_overview_page.dart`
- **Dashboard (`lib/features/dashboard/`):**
  - `presentation/pages/dashboard_page.dart`
- **Tests:**
  - `test/features/business_profile_test.dart`
  - `test/features/lots_designs_colours_photos_test.dart`
  - `test/features/inventory_overview_test.dart`
  - `test/widget/milestone_4_ui_test.dart`

### Modified Files
- `lib/core/database/daos/lot_dao.dart` (+ `.g.dart`) — Added update, soft-delete, and active list query methods (zero schema changes).
- `lib/core/router/{route_paths.dart, app_router.dart}` — Mounted `StitchFlowShellPage` using `ResponsiveNavigation` (`Dashboard`, `Lots`, `Inventory`, `Business Profile`, `/lots/:id`, and `dev`-accessible `/showcase`).
- `lib/l10n/{app_en.arb, app_gu.arb}` (+ generated `app_localizations*.dart`) — Added 80 bilingual keys with `0` untranslated entries (`l10n_untranslated.txt` = `{}`).
- `lib/core/di/injection.config.dart` — Regenerated with all Milestone 4 repositories & Cubits.
- `test/widget_test.dart`, `test/widget/design_system_widgets_test.dart`, `CHANGELOG.md`, `README.md`.

---

## 3. Photo Storage & Orphan-File Cleanup Strategy

1. Photos are captured via `image_picker` with native `maxWidth: 1600`, `maxHeight: 1600`, and `imageQuality: 80` (preserving orientation and keeping file sizes compact).
2. `LotRepositoryImpl.addLotPhoto` writes bytes into private flavor-isolated storage (`media_<flavor>/lots/<lotId>/<uuid>.<ext>`) and computes SHA-256 via `MediaStorageService`.
3. Inside `DatabaseTransactionRunner`, it verifies the parent lot exists and inserts both `attachments` and `audit_logs`.
4. **Orphan Cleanup Guarantee:** If the database transaction fails for any reason (e.g., invalid parent lot or DB error), the `catch` block immediately deletes the written file (`_mediaStorage.deleteIfExists(saved.relativePath)`) before rethrowing—verified in `lots_designs_colours_photos_test.dart`.
5. Missing physical files on disk render a graceful localized fallback (`Photo file is unavailable.`) without crashing or exposing internal paths.

---

## 4. Commands Executed & Validation Results

| Command | Result |
| :--- | :--- |
| `flutter pub get` | **PASS** |
| `flutter gen-l10n` | **PASS** (`0` untranslated keys) |
| `dart run build_runner build` | **PASS** (`0` warnings) |
| `dart format .` | **PASS** |
| `flutter analyze` | **PASS** (`No issues found!`) |
| `flutter test` | **PASS** (`42 / 42` tests passed across unit, DB, repositories, pure inventory calculator, and EN/GU Light/Dark widget tests) |
| `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` | **PASS** (`build\app\outputs\flutter-apk\app-dev-debug.apk`) |

---

## 5. Known Issues & Pending Decisions

- **Physical Device / Emulator Note:** No Android emulator or physical USB device was attached in this CLI environment, so validation used automated unit/repository/widget tests plus a full Android `dev` debug APK build (honestly reported; physical phone install testing recommended on your Android device).
- **Email Field Note:** The current `business_profile` schema (`docs/07_database_schema.md`, `schemaVersion = 1`) stores `name_en`, `name_gu`, `owner_name`, `phone`, `address`, `logo_attachment_id`, and `default_billing_mode` (no `email` column). Per Section 11 ("Do not silently change schema version"), `schemaVersion = 1` was kept untouched; if you want an `email` column added, we can include it in a planned `v2` migration.
- **Next Milestone Approval:** Awaiting your review and approval before starting **Milestone 5 (Dynamic Processes, Workers/Members & Historical Pricing)**.
