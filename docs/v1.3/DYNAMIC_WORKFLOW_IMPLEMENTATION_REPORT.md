# StitchFlow V1.3 — Dynamic Process, Lot, Design, Colour, Worker, Pricing & Formatting Upgrade Report

## 1. Root Cause Analysis

Before modifying any code, an end-to-end investigation of UI, BLoCs/Cubits, repositories, calculators, and Drift tables identified six underlying root causes:

1. **Single-Process Limitation (`StockLabourSettingsPage`)**: The `+ Add Process` (`l10n.processCreateAction`) button was wrapped exclusively inside `if (_processes.isEmpty)`. Once any process (e.g., `Silay`) existed, the add action vanished from Stock & Labour Preferences. Additionally, Schema v7 `processes` already defined `default_rate_paise` and `default_pricing_unit`, but `ProcessEntity`, `ProcessRepository`, `ProcessFormPage`, and `StockLabourSettingsPage` ignored them.
2. **Disconnected Lot Creation (`LotListPage`)**: Creating a lot opened a minimal bottom sheet capturing only `lotNumber`, `title`, `date`, and `notes`, forcing users to jump into `LotDetailPage` → Add Design → Add Colour across multiple screens.
3. **Missing Direct Price Input in `VisualColourPickerSheet`**: `SelectedColourVariantInput` already included `unitPricePaise`, yet the sheet only rendered `Qty (pcs)` without a `Unit Price (₹)` field, silently saving `₹0.00` for colours added from the palette.
4. **Disconnected Worker Creation (`WorkerFormPage`)**: Worker creation only captured contact fields, requiring separate navigation to `WorkerAssignmentsPage` and `RateFormPage` per process.
5. **Inconsistent Labour Rate Precedence**: `StockMovementRepositoryImpl` required a worker-specific rate (blocking stock issue even when the process had `default_rate_paise > 0`), whereas `ProcessRoutingRepositoryImpl` checked the process default *before* the worker's historical rate.
6. **Scattered Currency & Date/Time Formatting**: Several calculators, forms, pickers, and reports used raw `(paise / 100).toStringAsFixed(2)`, manual `$rupees.$rem`, raw ISO `YYYY-MM-DD` strings in UI (e.g., `AppDatePicker`, `RateHistoryPage`, `WorkerDetailPage`), or manual `padLeft` time formatting instead of centralized `intl` helpers.

---

## 2. Database Schema & Migration Impact

- **Schema Version:** Remains **v7 (Zero schema migration required)**.
- Every required column already existed in Schema v7:
  - `processes`: `default_rate_paise`, `default_pricing_unit`, `billing_mode_override`, `include_damaged_in_labour`, `is_active`
  - `lots`, `lot_designs`, `design_colours` (`unit_price_paise`, `initial_quantity`, `colour_hex`), `colour_masters`
  - `members`, `member_processes` (`is_active`), `member_process_rates` (`rate_paise`, `effective_from`, `effective_to`)
- SQLite durability settings (`WAL`, `synchronous=FULL`, `foreign_keys=ON`, `busy_timeout=5000`), existing `Silay` records, and all historical `stock_movements` / `labour_entries` remain 100% preserved.

---

## 3. Unified Pricing Architecture & Precedence Rules

### Strict Separation of Price Types
- **SKU / Variant Unit Price (`design_colours.unit_price_paise`)**: Reference unit value for inventory valuation and reports — never mixed with worker labour rates.
- **Process Default Labour Rate (`processes.default_rate_paise` + `default_pricing_unit`)**: Process-level fallback labour rate supporting `PER_PIECE`, `PER_DOZEN`, `PER_LOT`, and `FIXED_AMOUNT`.
- **Worker-Specific Process Labour Rate (`member_process_rates.rate_paise`)**: Effective-dated per-piece override for `(workerId, processId)`.

### Unified Labour Rate Resolution Precedence (Stock Issue & Multi-Process Routing)
1. **Worker-specific process rate** (`RateResolutionFound` — badge: `Worker Rate`)
2. **Process-level default rate** (`RateResolutionProcessDefault` — badge: `Process Default`; normalizes `PER_DOZEN` cleanly to per-piece paise for piece-based Stock Issue)
3. **Missing** (`RateResolutionMissing` — allows explicit manual override with reason when permitted)

Existing `RECEIVED_QTY` vs. `GIVEN_QTY` billing modes, `includeDamagedInLabour` toggles, and historical rate immutability remain completely intact.

---

## 4. System-Wide Indian Rupee (`intl` `en_IN`) & Common Date/Time Formatting

- **`MoneyFormatter` (`lib/core/utils/money_formatter.dart`)**:
  - Standard Indian accounting format via `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)` (`₹1,25,000.00`, `-₹25.50`).
  - Added `formatSignedPaise`, `formatPaiseWithoutSymbol`, `formatPaiseForInput`, `formatRatePaise`, `shortUnitSuffix`, and `formatQuantity` (`1,25,000`).
  - Eliminated raw `/ 100`, `.toStringAsFixed(2)`, and manual `$rupees.$rem` formatting across `ledger_calculator.dart`, `lot_detail_page.dart`, `job_process_routing_page.dart`, `rate_form_page.dart`, and `worker_ledger_page.dart`.
- **`AppDateTimeFormatter` (`lib/core/utils/app_date_time_formatter.dart`)**:
  - Centralized `Asia/Kolkata` (IST) formatter with cached `intl` `DateFormat` instances per `(pattern, locale)` for 120Hz scrolling speed.
  - Standardized UI display formats to `"24 Nov 2026"` (`dd MMM yyyy`) and `"24 Nov 2026, 04:15 PM"` (`dd MMM yyyy, hh:mm a`, localized EN/GU month names + 12-hour AM/PM).
  - Unified `IstDateTimeHelper` (delegates all formatting to `AppDateTimeFormatter`), `AppDatePicker`, `RateHistoryPage`, `WorkerDetailPage`, `StockIssuePage`, `LotListPage`, `ProcessDetailPage`, `NotificationSettingsPage`, `DailySummaryPage`, `ReportsAnalyticsCalculator`, `ReportsPage`, `ReportHtmlBuilder`, `MemberProcessRateResolver`, `NativeBackupRestoreService`, and `AppLockScreen`.

---

## 5. Before vs. After Workflow Comparison

| Workflow | Before | After |
| :--- | :--- | :--- |
| **Add Additional Processes** | `+ Add Process` disappeared in Stock & Labour Preferences once `Silay` existed. | Always-visible `+ New Process` action in AppBar & section header, inline billing mode & damaged-qty rules, default labour rate + pricing unit, edit & activate/deactivate controls. |
| **Create Lot + Designs + Colours + Prices** | 3–4 separate modals/screens (`LotListPage` sheet → `LotDetailPage` → Add Design → Add Colour → Edit Price). | Single full-screen `LotCreatePage` (`/lots/new`) with Lot Info, searchable existing designs + inline `+ Add New Design` (no navigation away), multi-colour visual picker with direct Qty & INR Unit Price, live Total Qty & SKU Value, and atomic transactional save. |
| **Add Design / Colour on Existing Lot** | Visual Colour Picker omitted Unit Price (`₹0.00`); Add Design couldn't add initial colours. | `VisualColourPickerSheet` captures per-colour Qty & INR Unit Price with live valuation; Add Design supports default unit price + initial colours saved atomically without modifying other variants. |
| **Create / Edit Worker + Processes + Rates** | 3 separate screens (`WorkerFormPage` → `WorkerAssignmentsPage` → `RateFormPage`). | Single-screen `WorkerFormPage` with Active/Inactive toggle, multi-process checkboxes, inline `+ New Process` shortcut, inherited process default badges vs. optional custom worker rate inputs, saved atomically in one transaction. |
| **Worker Process Deactivation & Reassignment** | Only active links shown; no inline rate entry on assignment. | `WorkerAssignmentsPage` supports optional custom rate on assignment + one-tap Reactivate for deactivated links while preserving all historical labour & stock records. |

---

## 6. Key Files Created & Modified

### Created
- `lib/core/utils/app_date_time_formatter.dart`
- `lib/features/lots/presentation/pages/lot_create_page.dart`
- `test/unit/money_and_date_formatter_test.dart`
- `test/features/dynamic_workflow_pricing_test.dart`
- `test/widget/dynamic_workflows_ui_test.dart`

### Modified
- **Formatting & Core**: `lib/core/utils/money_formatter.dart`, `lib/core/utils/ist_datetime_helper.dart`, `lib/core/widgets/app_date_picker.dart`, `lib/core/router/route_paths.dart`, `lib/core/router/app_router.dart`
- **Processes & Settings**: `lib/features/processes/domain/entities/process_entities.dart`, `process_repository.dart`, `process_repository_impl.dart`, `process_form_page.dart`, `process_list_page.dart`, `process_detail_page.dart`, `lib/features/settings/presentation/pages/stock_labour_settings_page.dart`
- **Lots, Designs & Colours**: `lib/features/lots/domain/repositories/lot_repository.dart`, `lot_repository_impl.dart`, `lot_detail_cubit.dart`, `lot_list_page.dart`, `lot_detail_page.dart`, `visual_colour_picker_sheet.dart`
- **Workers, Assignments & Unified Pricing**: `lib/features/workers/domain/entities/worker_entities.dart`, `worker_repository.dart`, `worker_repository_impl.dart`, `worker_form_page.dart`, `worker_detail_page.dart`, `worker_assignments_cubit.dart`, `worker_assignments_page.dart`, `lib/features/rates/domain/entities/rate_entities.dart`, `lib/features/stock_movements/data/repositories/stock_movement_repository_impl.dart`, `stock_issue_page.dart`, `lib/features/process_routing/data/repositories/process_routing_repository_impl.dart`
- **System-Wide Formatting Migrations**: `ledger_calculator.dart`, `worker_ledger_page.dart`, `job_process_routing_page.dart`, `rate_form_page.dart`, `rate_history_page.dart`, `member_process_rate_resolver.dart`, `notification_settings_page.dart`, `daily_summary_page.dart`, `reports_analytics_calculator.dart`, `reports_page.dart`, `report_html_builder.dart`, `native_backup_restore_service.dart`, `app_lock_screen.dart`

---

## 7. Verification Summary

- `dart run build_runner build` — Succeeded cleanly (648 outputs).
- `flutter analyze` — **0 issues found**.
- `flutter test` — All unit, repository, database migration, formatter, and widget tests passing (including 360dp EN/GU Light & Dark Glass layout checks).
