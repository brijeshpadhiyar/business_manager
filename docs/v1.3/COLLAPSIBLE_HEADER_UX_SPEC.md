# StitchFlow V1.3 – Collapsible Header UX Specification

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`

---

## 1. Visual States

### Expanded State (Scroll Offset = 0)
- **Large Title** (`headlineSmall`, `w700`) with optional **Subtitle** (`bodySmall`, muted contrast) and primary header **Actions** (e.g., `+ New Lot`, `+ Add Worker`, `Refresh`).
- **Collapsible Summary Strip**: Compact translucent glass KPI chips/cards displaying live BLoC-backed metrics (e.g., Active Lots, Completed Lots, Total Workers, Active Workers, Earned Labour, Outstanding Payable) that collapse smoothly upward as the user scrolls.
- **Pinned Search & Filters**: Rendered immediately below the `SliverAppBar` via `SliverPersistentHeader(pinned: true)` so search (`AppSearchField`) and status/active `FilterChip`s remain one tap away during long scrolling.

### Collapsed State (Scrolled Past Threshold)
- **Compact Pinned Toolbar (`56dp`)**: Frosted glass bar (`tokens.navGlassFill` + hairline `tokens.navGlassBorder`) displaying the compact title (`titleMedium`, `w700`) and key actions with crisp contrast in both Light Glass and Dark Glass.
- **Summary Strip**: Smoothly fades and translates out via native `FlexibleSpaceBar` parallax/collapse interpolation without jumps or title overlap.
- **Pinned Search & Filter Bar**: Remains cleanly pinned beneath the compact toolbar.

## 2. Theme Integration (Light Glass & Dark Glass)
- Uses `context.surfaceTokens` (`navGlassFill`, `navGlassBorder`, `glassFill`, `glassBorder`) and `Theme.of(context).colorScheme` exclusively — zero hardcoded light/dark colors.
- High-contrast text and icon legibility verified across English and Gujarati (including long Gujarati strings at `360dp` width).

## 3. Accessibility & Reduced Motion
- Explicit `Semantics(header: true)` on expanded/collapsed titles.
- Touch targets >= `44dp` on all header actions and filter chips.
- Reduced-motion (`AppMotion.reduceMotion(context)`) disables entrance animations while preserving native sliver scrolling.
