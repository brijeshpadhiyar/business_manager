# StitchFlow — Responsive UX & Accessibility Audit

**Audit Date:** 2026-11-24  
**Target Viewport Matrix:** Mobile (`360px`, `390px`, `430px`), Tablet (`600px`, `768px`, `1024px`), Desktop/Web (`1280px`, `1440px`, `1920px`).

---

## 1. Breakpoint & Constraint Architecture Audit

| Aspect | Current Implementation | Audit Finding | Resolution (Phase 2) |
|---|---|---|---|
| Breakpoints | `AppBreakpoints`: `< 600` compact, `600–1023` medium, `>= 1024` expanded | Matches directive exactly. However, `ResponsiveNavigation` and `AppDataTable.buildSliver` read `MediaQuery.sizeOf(context).width` instead of `LayoutBuilder` available constraints. | Prefer `LayoutBuilder` constraints for content/table layout decisions so split panes, sidebar-offset bodies, and live browser resizes stay overflow-free. |
| Content Width | Single `AppSizing.maxContentWidth = 1120` across all pages | Too wide for narrow forms/settings (uncomfortable line length on 1920px), too cramped for multi-column operational tables & dashboards on 1440px–1920px. | Introduce `AppContentWidth` tiers: `narrow (840dp)`, `standard (1160dp)`, `wide (1480dp)`, `fluid`. |
| Navigation Chrome | `StitchFlowShellPage` only lives at `/` | Navigating to `/lots/:id`, `/processes`, `/history`, `/reports`, `/accounting`, etc. **destroys** the Desktop Sidebar and Tablet Rail, and refreshing `/lots` resets to Dashboard. | Move to GoRouter `ShellRoute` with real section URLs (`/`, `/lots`, `/stock`, `/workers`, `/settings`), persistent Tablet Rail & Desktop Sidebar across all routes, and automatic `AppBreadcrumbBar`. |
| Headers | `AppScaffold` supports `standard`, `collapsible`, `compact` | Well engineered! Need `ResponsiveShellScope` awareness so pages inside the persistent Desktop/Tablet shell don't duplicate `AppGlassBackdrop` or clip breadcrumbs. | Integrate `ResponsiveShellScope` + optional `breadcrumbs` into `AppScaffold`. |
| Data Tables | `AppDataTable` wraps Material `DataTable` in horizontal `SingleChildScrollView` | No pagination controls, no column sorting, no responsive column priority (hiding lower-priority columns on 600–768px tablet), and only 3 of 45 pages use it. | Upgrade `AppDataTable` with built-in pagination, sortable column headers, `minWidthClass` column priority, and adopt across all operational list/ledger/history/report screens. |
| Dialogs & Sheets | `AppDialog` (`maxWidth: 520`), `AppBottomSheet` (bottom sheet on mobile, centered glass dialog on tablet/desktop) | Strong existing adaptive foundation; ensure scroll safety on short viewports and keyboard `Esc` dismissal. | Preserve adaptive behavior and add Semantics / focus polish. |

---

## 2. Glassmorphism & Theme Audit

- **Themes Supported:** Light Glass, Dark Glass, and System mode via `ThemeCubit` + `AppTheme.light()` / `AppTheme.dark()` + `AppSurfaceTokens` theme extension.
- **BackdropFilter Performance:** Good news — zero of the 45 feature pages apply `BackdropFilter` inside list/table rows. `BackdropFilter` is already confined to bounded chrome (`AppBar`, `NavigationBar`, `NavigationRail`, `NavigationDrawer`, `AppCollapsibleHeader`, `AppDialog`, `AppBottomSheet`).
- **Reduced Motion:** `AppMotion.reduceMotion(context)` exists and respects `MediaQuery.disableAnimationsOf(context)`. Must be verified across `AppAnimatedNumber`, `AppDialog`, `AppBottomSheet`, and page transitions.
- **Focus Visibility:** `AppTheme` needs explicit, crisp high-contrast `focusColor` / keyboard focus border rings on buttons, inputs, and interactive cards for Desktop & Web keyboard navigation.

---

## 3. Accessibility & Usability Audit

| Check | Current State | Action Plan (Phase 4) |
|---|---|---|
| Explicit `Semantics` labels | 0 / 45 pages use explicit `Semantics(...)` | Add semantic labels to core components (`AppMetricTile`, `AppStatusBadge`, `AppColourSwatch`, `AppCard.listItem`, `AppDataTable`, `AppBreadcrumbBar`) and key screen controls. |
| Touch Targets | `AppSizing.touchTargetMin = 48` defined, some compact icon buttons/chips sit below 48dp | Enforce `48dp` minimum hit area on interactive buttons, filter chips, pagination controls, and breadcrumb links. |
| Empty / Loading / Error States | 25+ pages have empty/error states; several detail/form pages lack retry or empty guidance | Standardize `AppSkeletonList`, `AppEmptyState` (with primary action CTA), and `AppErrorView` (with Retry) across all data-driven screens. |
| Form Usability | Some large forms (`LotCreatePage`, `StockIssuePage`) stack many fields vertically without section cards or double-submit indicators | Adopt `AppFormSection` (responsive 1-col mobile / 2-col desktop), `*` required markers, clear helper hints, inline validation, and submission locks. |
| Bilingual Terminology (EN + GU) | Comprehensive `app_en.arb` + `app_gu.arb` | Add localized keys for every new UI element (Designs & Colours, Breadcrumbs, Pagination, Sort, Web Backup/Print) with zero hardcoded strings. |
