# 15 — Design System (Material 3)

## 1. Design Philosophy

- **Official Material 3 Foundation (`material_ui: ^1.11.1`):** Built on Flutter's official decoupled Material 3 library (`package:material_ui/material_ui.dart`, published by `flutter.dev`, `useMaterial3: true`), avoiding third-party UI kits and duplicate implementations.
- **Compact & Professional:** Designed for high-density business data entry (lots, piece counts, rates, ledgers) on Android phones without wasted whitespace, while keeping comfortable tap targets and clear visual hierarchy.
- **Token-Driven:** Zero hardcoded colors, paddings, radii, or font sizes in feature screens.

---

## 2. Core Design Tokens (Centralized & Adjustable)

### Spacing (`AppSpacing`)
| Token | Value (dp) | Usage |
| :--- | :---: | :--- |
| `xs` | `4` | Micro gaps (badge padding, icon-label tight gap) |
| `sm` | `8` | Small padding, default gap between elements |
| `md` | `12` | Card internal padding, compact section gap |
| `lg` | `16` | Screen horizontal padding, standard section gap |
| `xl` | `24` | Large layout section separation |

### Sizing (`AppSizing`)
| Token | Value (dp) | Usage |
| :--- | :---: | :--- |
| `inputHeight` | `44` | Compact form inputs & dropdowns |
| `buttonHeight` | `40` | Compact primary/secondary buttons (padded to 48dp accessible hit area where needed) |
| `appBarHeight` | `56` | Standard Material AppBar |
| `iconSm` | `16` | Inline table/badge icons |
| `iconMd` | `20` | Default UI & button icon size |
| `iconLg` | `24` | Navigation & header icons |

### Radius (`AppRadius`)
| Token | Value (dp) | Usage |
| :--- | :---: | :--- |
| `sm` | `6` | Status badges, small chips |
| `md` | `8` | Default border radius (cards, buttons, inputs, dialogs) |
| `lg` | `12` | Bottom sheets, modal containers |
| `full` | `999` | Pills, circular avatars |

---

## 3. Theme Support & Persistence

- **Modes:** `ThemeMode.system` (default), `ThemeMode.light`, `ThemeMode.dark`.
- **Persistence:** Saved via `shared_preferences` (`theme_mode` key) and managed by `ThemeCubit`.
- **Color System (Semantic Roles — WCAG AA Verified):**
  - **Primary (Indigo / Deep Slate Blue):** Trustworthy business primary (`#1E40AF` Light / `#93C5FD` Dark).
  - **Secondary (Teal):** Process & action accents (`#0F766E` Light / `#5EEAD4` Dark).
  - **Semantic Business Status Tokens (Custom `ThemeExtension<AppSemanticColors>`):**
    - `goodStock` / `success` (Emerald Green): Good returns, settled balances.
    - `pending` / `warning` (Amber): Pending pieces with workers, partial returns.
    - `damaged` / `danger` (Crimson Red): Damaged stock, lost/shortage, overdue/errors.
    - `advanceCredit` / `info` (Cyan/Blue): Worker advance credit (negative pending payable).

---

## 4. Typography & Gujarati Script Support

- **Primary Font Stack:** `NotoSansGujarati` bundled locally with clean Latin fallback so English numbers/labels and Gujarati script (`બિઝનેસ મેનેજર`) share balanced baseline alignment and line height.
- **Tabular Figures (`FontFeature.tabularFigures()`):** Applied to all piece quantities, rates (`₹20.00`), labour amounts, and ledger columns so numbers align vertically in tables and summary cards.
- **Type Scale:** Compact Material 3 scale (`titleLarge: 18sp`, `titleMedium: 15sp`, `bodyMedium: 14sp`, `bodySmall: 12sp`, `labelLarge: 13sp`).
