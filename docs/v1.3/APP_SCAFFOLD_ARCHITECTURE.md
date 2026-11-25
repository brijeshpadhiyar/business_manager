# StitchFlow V1.3 – Adaptive `AppScaffold` Architecture

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`  
**Status:** Implemented & Verified

---

## 1. Existing Architecture Audit

Before this upgrade, `lib/core/widgets/app_scaffold.dart` supported only a single fixed layout:
- `AppGlassBackdrop` → `Scaffold` → fixed `56dp` frosted `AppBar` → `SafeArea` → `Align` / `ConstrainedBox(maxWidth: 1120)` → `body`.
- Data-heavy list screens (`LotListPage`, `WorkerListPage`, `ProcessListPage`, `InventoryOverviewPage`, `AccountingOverviewPage`) manually built a `Column` with a fixed header + `AppTextField` + `FilterChip`s + `Expanded(ListView.separated)` or an eager `ListView(children: [...])`, wasting vertical space on mobile and lacking collapsible summary KPIs or pinned search/filter headers.
- Shell tab pages (`LotListPage`, `WorkerListPage`, `DashboardPage`) live inside `ResponsiveNavigation`'s `Scaffold`, while pushed pages (`InventoryOverviewPage(showAppBar: true)`, `ProcessListPage(showAppBar: true)`, `AccountingOverviewPage`) own their own `AppScaffold`.

---

## 2. Proposed Architecture & Three Scaffold Modes

Extend `AppScaffold` in place (zero competing scaffolds, 100% backward-compatible) with:

```dart
enum AppScrollMode {
  standard,
  collapsible,
  compact,
}
```

### Public API

| Parameter | Type | Default | Description |
|---|---|---|---|
| `scrollMode` | `AppScrollMode` | `AppScrollMode.standard` | Selects Standard, Collapsible, or Compact internal layout |
| `embedded` | `bool` | `false` | When `true`, omits outer `AppGlassBackdrop`/`Scaffold` for screens embedded inside `ResponsiveNavigation` |
| `title` / `titleWidget` | `String?` / `Widget?` | `null` | Standard/Compact toolbar title |
| `actions` / `leading` | `List<Widget>?` / `Widget?` | `null` | Toolbar actions & leading widget |
| `body` | `Widget?` | `null` | Required in `standard`/`compact` (optional in `collapsible` when `slivers` provided) |
| `header` | `AppCollapsibleHeader?` | `null` | Collapsible header configuration (title, subtitle, summary, actions, expandedHeight, pinned, background) |
| `pinnedHeader` | `Widget?` | `null` | Pinned search/filter bar rendered via `SliverPersistentHeader(pinned: true)` |
| `pinnedHeaderHeight` | `double` | `104` | Height of `pinnedHeader` delegate |
| `slivers` | `List<Widget>?` | `null` | Primary lazy slivers (`SliverList`, `SliverGrid`, `SliverToBoxAdapter`, `SliverFillRemaining`) |
| `scrollController` | `ScrollController?` | `null` | Optional externally owned controller (never disposed by `AppScaffold`) |
| `onRefresh` | `Future<void> Function()?` | `null` | Optional `RefreshIndicator` wrapping the primary `CustomScrollView` |
| `collapseOnDesktop` | `bool` | `false` | By default desktop (`>= 1024dp`) uses a compact header to maximize workspace |

### Internal Modular Components

1. **`AppScrollMode`** (`lib/core/widgets/app_scaffold.dart`): Enum selecting `_StandardScaffoldLayout`, `_CollapsibleScaffoldLayout`, or `_CompactScaffoldLayout`.
2. **`AppCollapsibleHeader`** (`lib/core/widgets/app_collapsible_header.dart`): Data/configuration model + native `SliverAppBar` builder (`buildSliver`) using `FlexibleSpaceBar` and `LayoutBuilder` collapse-ratio interpolation (zero extra `AnimationController`s, zero `setState` on scroll).
3. **`AppPinnedSliverHeader`** (`lib/core/widgets/app_collapsible_header.dart`): Reusable `SliverPersistentHeaderDelegate` wrapping pinned search/filter controls in a lightweight frosted glass bar with hairline bottom border.
4. **`AppSummaryStrip`** (`lib/core/widgets/app_collapsible_header.dart`): Compact, responsive summary metric strip designed for the expanded header area (fits cleanly without overflow on 360dp phones, tablets, and desktops).

---

## 3. Adaptive Responsive Behavior (`AppBreakpoints`)

| Width (`AppWindowSizeClass`) | Collapsible Mode Behavior |
|---|---|
| **`< 600dp` (Mobile / Compact)** | Full collapsible `SliverAppBar` (`expandedHeight`), expanded large title + subtitle + summary strip, collapses smoothly to pinned `56dp` frosted toolbar. Pinned search/filter stays accessible below. |
| **`600–1023dp` (Tablet / Medium)** | Reduced expanded height (~85%, balanced horizontal summary layout), smooth collapse to pinned `56dp` toolbar. |
| **`>= 1024dp` (Desktop / Expanded)** | Compact pinned header (`56dp`) + inline summary strip above pinned search/filters by default (unless `collapseOnDesktop: true`), preserving maximum workspace. |

---

## 4. Migration Strategy

- **Priority 1 (Migrated to `AppScrollMode.collapsible`)**:
  - `LotListPage` (embedded, collapsible summary KPIs + pinned `AppSearchField` + status filter chips + `SliverList`)
  - `WorkerListPage` (embedded, collapsible summary KPIs + pinned `AppSearchField` + active filter chips + `SliverList`)
  - `ProcessListPage` (both standalone & embedded, collapsible summary KPIs + pinned `AppSearchField` + active filter chips + `SliverList`)
  - `InventoryOverviewPage` (both standalone & embedded, collapsible summary KPIs + pinned tab chips + sliver table)
- **Priority 2 (Migrated to `AppScrollMode.collapsible`)**:
  - `AccountingOverviewPage` (standalone, collapsible financial KPIs + `SliverList` of worker balances & payments)
- **Intentionally Kept `AppScrollMode.standard`**:
  - Create/Edit forms (`WorkerFormPage`, `ProcessFormPage`, `RateFormPage`, `PaymentFormPage`, `StockIssuePage`, `StockSettlementPage`, `DamagedRepairPage`), Security/PIN screens, Settings pages, Business Profile, Backup & Restore.

---

## 5. Performance Considerations

- Single `CustomScrollView` per collapsible screen — zero nested vertical scrollables.
- Lazy `SliverList.separated` / `SliverChildBuilderDelegate` with stable `ValueKey`s.
- Controlled Glassmorphism: `BackdropFilter` only on the pinned `56dp` toolbar / pinned header bar (never animating blur sigma per frame), wrapped in `RepaintBoundary`.
- Respects `MediaQuery.maybeDisableAnimationsOf(context)` (reduced motion).
