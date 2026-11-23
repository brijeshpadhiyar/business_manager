# 34 — StitchFlow Premium UI/UX Design System

**Status:** Active (Verified on Flutter `3.50.1` / Dart `3.14.0` / `material_ui: ^1.11.1`)  
**Brand Identity:** **StitchFlow** (`સ્ટિચફ્લો`) — *From Fabric to Finished.*

---

## 1. Design Philosophy & Brand Identity

StitchFlow serves real garment and tailoring workshops on Android phones, tablets, and desktops. The design system combines **premium modern Material 3 visual polish** with **high-contrast business legibility**, prioritizing stock accuracy, readable tabular numbers, fast data entry, and effortless offline operation.

### Official Brand Palette (Preserved)
| Role | Token | Hex | Usage |
| :--- | :--- | :---: | :--- |
| Primary | `AppColors.brandNavy` | `#172B4D` | Primary actions, brand headers, hero gradient start |
| Secondary | `AppColors.brandTeal` | `#0D9488` | Active highlights, focus rings, icon accents, gradient end |
| Accent | `AppColors.brandAmber` | `#F4A340` | Highlight accents, pending indicators |
| Soft Background | `AppColors.brandSoftWhite` | `#F5F7FA` | Light theme canvas background |

### Refined Supporting Surfaces & Semantic Colors
- **Light Surfaces:** Pure white elevated cards (`#FFFFFF`) on soft mist canvas (`#F5F7FA`) with `#E2E8F0` hairline borders and subtle `#172B4D` ambient shadow (`6%` opacity).
- **Dark Surfaces:** Layered deep navy slate (`#0D1422` canvas → `#131D2E` cards → `#1B2840` elevated containers) with `#283854` crisp borders.
- **Business Semantics (`AppSemanticColors` ThemeExtension):**
  - `goodStock` — Emerald (`#15803D` Light / `#86EFAC` Dark)
  - `pending` — Warm Amber (`#B45309` Light / `#FCD34D` Dark)
  - `damaged` — Crimson (`#B91C1C` Light / `#FCA5A5` Dark)
  - `advanceCredit` — Sky Blue (`#0369A1` Light / `#7DD3FC` Dark)
- **Hero Gradients:** `AppColors.heroGradientLight` / `AppColors.heroGradientDark` (`#172B4D → #1A3D61 → #0F766E`) used selectively on Dashboard headers and featured summary banners.

---

## 2. Selective Glassmorphism Policy (`AppSurfaceTokens` + `AppGlassSurface`)

Glassmorphism (`BackdropFilter` with `sigmaX: 12, sigmaY: 12`, semi-transparent tint, and hairline specular border) is applied **selectively** to avoid readability loss or GPU overdraw:

- **Allowed:** Dashboard KPI highlights, top/bottom translucent navigation surfaces, branded hero cards, and modal overlays.
- **Avoided:** Dense forms, multi-column `AppDataTable` grids, long scrollable transaction ledgers, and input fields (always use solid high-contrast surfaces).

---

## 3. Spacing, Radius, Sizing & Typography

- **Spacing (`AppSpacing`):** `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`.
- **Radii (`AppRadius`):** `sm=6`, `md=10` (buttons, inputs, chips), `lg=14` (cards, dialogs), `xl=18` (hero banners, modal sheets), `full=999` (status pills, halos).
- **Typography (`AppTypography`):** Bundled `NotoSansGujarati` (400/500/600/700) for clean English & Gujarati alignment; `AppTypography.tabular(...)` (`FontFeature.tabularFigures()`) applied to all stock quantities, rates, paise amounts, and ledger columns.
- **Theme Mode:** `ThemeMode.system` remains the default, with persisted Light/Dark/System override via `ThemeCubit`.

---

## 4. Motion & Animation System (`AppMotion`)

| Motion Type | Duration | Curve | Implementation |
| :--- | :---: | :--- | :--- |
| Top-level tab switches | `160ms` | M3 Fade Through | `PageTransitionSwitcher` + `FadeThroughTransition` (`animations`) |
| Route navigation | `240ms` / `160ms` rev | M3 Shared Axis | `AppMotion.buildPage` + `SharedAxisTransition` (`animations`) |
| Dialogs & tablet sheets | `160ms` | M3 Fade Scale | `showModal` + `FadeScaleTransitionConfiguration` (`animations`) |
| Card / list entrance | `240ms` (capped stagger) | `Curves.easeOutCubic` | `AppMotionEntrance` (`flutter_animate`) |
| Button press feedback | `90ms` | `Curves.easeOut` | `AnimatedScale(0.97)` inside `AppButton` |
| Dashboard counters | `420ms` | `Curves.easeOutCubic` | `AppAnimatedNumber` (`TweenAnimationBuilder`) |

### Accessibility & Reduced Motion
- `AppMotion.reduceMotion(context)` inspects `MediaQuery.maybeDisableAnimationsOf(context)`.
- When reduced motion is requested, transitions and counters collapse cleanly to `Duration.zero`.
- Zero continuous infinite looping animations are used on normal screens, preserving battery life on Android phones and deterministic test execution.

---

## 5. Centralized Common Widget Library (`lib/core/widgets/`)

All screens use centralized widgets (zero duplicate widget systems):
- **Layout & Navigation:** `AppScaffold`, `ResponsiveNavigation`
- **Surfaces & KPIs:** `AppCard`, `AppGlassSurface`, `AppMetricTile`, `AppAnimatedNumber`, `AppStatusBadge`
- **Inputs & Forms:** `AppTextField`, `AppDropdown`, `AppDatePicker` (supports date-only and IST date+time), `AppCheckbox`, `AppRadio`, `AppSwitch`, `AppButton`, `AppIconButton`
- **Data & Feedback:** `AppDataTable`, `AppDialog`, `AppBottomSheet`, `AppEmptyState`, `AppErrorView`, `AppLoader`, `AppSkeletonBox`, `AppSkeletonList`, `AppFeedback`, `AppHeading`, `AppText`

---

## 6. Selected Packages & Compatibility Verification

| Package | Version | Publisher | Verification & Justification |
| :--- | :---: | :--- | :--- |
| `material_ui` | `^1.11.1` | `flutter.dev` | Preserved official decoupled Material 3 foundation |
| `animations` | `^3.0.0` | `flutter.dev` | Official Material 3 motion transitions (`FadeThroughTransition`, `SharedAxisTransition`, `FadeScaleTransition`); verified compatible with Flutter `3.50.1` / Dart `3.14.0` across all 6 platforms |
| `flutter_animate` | `^4.5.2` | community (widely adopted) | Lightweight declarative entrance animations with zero native dependencies; verified compatible with Flutter `3.50.1` / Dart `3.14.0` |
| Native `BackdropFilter` | Flutter SDK | `flutter.dev` | Used directly inside `AppGlassSurface` instead of adding a redundant third-party glassmorphism package |
| Native `TweenAnimationBuilder` | Flutter SDK | `flutter.dev` | Used directly inside `AppAnimatedNumber` for zero-overhead counter transitions |
