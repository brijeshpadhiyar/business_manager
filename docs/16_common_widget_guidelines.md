# 16 — Common Widget Guidelines

All shared UI components live in `lib/core/widgets/` and are built on Flutter's official decoupled Material 3 package (`material_ui: ^1.11.1`, `package:material_ui/material_ui.dart`) + centralized design tokens (`docs/15_design_system.md`).

---

## 1. Guiding Principles

1. **Wrap with Purpose, Never Over-Wrap:** Do not wrap primitive Flutter layout widgets (`Row`, `Column`, `Padding`, `SizedBox`, `Expanded`). Only centralize components that enforce visual consistency, theming, localization, accessibility, or responsive behavior.
2. **Feature-Specific Widgets Stay in Features:** Complex domain widgets (e.g., `PartialReturnBreakdownCard`, `LotPhotoCarousel`, `MemberRateHistoryTile`) belong in `lib/features/<feature>/presentation/widgets/`.
3. **Mandatory Support Across All Common Widgets:**
   - Respect Light & Dark `ThemeData` and `AppSemanticColors`.
   - Accept localized strings (never hardcode default English labels inside widgets).
   - Provide `Semantics` labels and keyboard/focus support for desktop & accessibility.

---

## 2. Centralized Widget Library Inventory (20 Components)

| # | Widget | Purpose & Key API Features |
| :-: | :--- | :--- |
| 1 | `AppScaffold` | Unified page wrapper with `AppSizing.appBarHeight`, standard `16dp` horizontal padding option, offline/flavor banner slot, and responsive body max-width constraint. |
| 2 | `AppCard` | Consistent `12dp` padding, `8dp` border radius, subtle border in Light/Dark mode, optional tap handler with ink ripple. |
| 3 | `AppText` | Theme-aware text helper supporting semantic variants (`body`, `caption`, `numeric` with tabular figures) and overflow defaults. |
| 4 | `AppHeading` | Section & screen headings (`h1`, `h2`, `h3`) with optional trailing action widget. |
| 5 | `AppButton` | Variants: `primary`, `secondary`, `outlined`, `destructive`, `text`. Standard `40dp` height, `8dp` radius, built-in `isLoading` spinner & disabled state. |
| 6 | `AppIconButton` | `20dp` icon inside accessible `48dp` touch target, mandatory localized `tooltip`. |
| 7 | `AppTextField` | `44dp` compact height, `8dp` radius, consistent label/hint/error/prefix/suffix, numeric/currency input formatters. |
| 8 | `AppDropdown<T>` | Type-safe Material 3 dropdown with search/filter option for large lists (Lots, Members, Processes), consistent `44dp` height. |
| 9 | `AppDatePicker` | Date & DateTime selector that formats in `Asia/Kolkata` (`IST`) and emits UTC `DateTime` values to callers. |
| 10 | `AppCheckbox` | Accessible checkbox + label tile with compact density. |
| 11 | `AppRadio<T>` | Accessible radio option tile (e.g., billing mode, theme, language). |
| 12 | `AppSwitch` | Compact Material 3 switch tile (e.g., process active toggle, `include_damaged_in_labour`). |
| 13 | `AppDialog` | Adaptive modal dialog (confirmations, rate override confirmation with mandatory reason input, destructive warnings). |
| 14 | `AppBottomSheet` | Adaptive bottom sheet on mobile → centered dialog on tablet/desktop (`docs/19_responsive_ui_strategy.md`). |
| 15 | `AppLoader` | Consistent inline and full-screen loading indicator with optional localized message. |
| 16 | `AppEmptyState` | Consistent icon + localized title + subtitle + optional primary CTA button. |
| 17 | `AppErrorView` | Consistent error presentation with localized message and Retry button. |
| 18 | `AppStatusBadge` | Compact semantic pill (`Good`, `Pending`, `Damaged`, `Lost`, `Advance Credit`, `Active`, `Inactive`) backed by `AppSemanticColors`. |
| 19 | `AppDataTable<T>` | Responsive data display: renders compact card list on mobile (`< 600dp`) and sortable scrollable `DataTable` on tablet/desktop (`>= 600dp`). |
| 20 | `AdaptiveShellScaffold` | Responsive navigation shell switching between Mobile Bottom Navigation Bar, Tablet NavigationRail, and Desktop Navigation Sidebar. |
