# StitchFlow V1.3 – Shared UI Component Audit Report

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`

## 1. Shared Component Layer (`lib/core/widgets/` & `lib/core/services/`)

All 31 shared UI widgets are exported cleanly from `lib/core/widgets/widgets.dart`:
- **Structure & Chrome**: `AppScaffold`, `ResponsiveNavigation`, `AppGlassBackdrop`, `AppGlassSurface`, `AppSectionHeader` (new)
- **Overlays & Messaging**: `AppDialog` (enhanced with icon, tone & scrollable body), `AppConfirmationDialog` (new), `AppBottomSheet`, `AppMessageService` (`lib/core/services/app_message_service.dart`, new), `AppFeedback` (facade delegating to `AppMessageService`)
- **Inputs & Controls**: `AppButton`, `AppIconButton`, `AppTextField`, `AppSearchField` (new), `AppDropdown`, `AppDatePicker`, `AppCheckbox`, `AppRadio`, `AppSwitch`
- **Data & Visuals**: `AppCard`, `AppMetricTile`, `AppDataTable`, `AppStatusBadge`, `AppHeading`, `AppText`, `AppAnimatedNumber`, `AppColourSwatch`
- **States**: `AppLoader` (enhanced with `AppLoader.inline`), `AppSkeletonBox` / `AppSkeletonList`, `AppEmptyState`, `AppErrorView`, `AppSuccessState` (new)

## 2. Duplicate & Bypass Migrations Completed

| Bypass Found | Locations Migrated | Replacement |
|---|---|---|
| Direct `ScaffoldMessenger.of(context).showSnackBar` | `lot_detail_page.dart` | `AppFeedback.showError` -> `AppMessageService` |
| Raw `showDialog` + `Dialog` (photo preview) | `lot_detail_page.dart` | `AppDialog.showCustom` + `AppDialog` |
| Raw `AlertDialog` (5 occurrences) | `accounting_overview_page.dart`, `worker_ledger_page.dart`, `stock_movements_page.dart`, `security_settings_page.dart`, `security_reauth_dialog.dart` | Frosted-glass `AppDialog` |
| Raw `CircularProgressIndicator` in photo tile | `lot_detail_page.dart` | `AppLoader.inline` |
| Plain `SnackBar` in `AppFeedback` (43 call sites) | All 15 feature screens | Automatically upgraded to Glassmorphism `AppMessageService` toasts |
