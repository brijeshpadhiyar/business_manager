# StitchFlow V1.1 — UI Fixes, Branded Splash Screen, Centralized Settings & Stock Workflow Redesign Report

**Release Version:** `1.1.0+2`  
**Target Stack:** Flutter `3.50.1` / Dart `3.14.0` / `material_ui: ^1.11.1` / Drift + SQLite (schema v2 preserved, zero DB reset)  
**Verification Date:** `2026-11-23` (`Asia/Kolkata`)

---

## 1. Executive Summary & Audit Findings

Following real-world garment workshop testing of StitchFlow V1 on Android devices, a full audit of typography, native Android launch resources, navigation, settings, and daily stock workflows uncovered specific engineering and UX root causes:

1. **Android Splash Screen Failure (Why the logo did not display):**
   - `android/app/src/main/res/drawable-v21/launch_background.xml` still contained Flutter's blank default template (`?android:colorBackground` with commented-out image). On Android 5.0+ (API 21+), `drawable-v21/` overrides `drawable/launch_background.xml`, resulting in a blank launch screen.
   - No `values-v31/styles.xml` or `values-night-v31/styles.xml` existed for Android 12+ (`windowSplashScreenBackground`, `windowSplashScreenAnimatedIcon`, `windowSplashScreenBrandingImage`).
   - `NormalTheme` used `?android:colorBackground` rather than StitchFlow's exact scaffold surfaces (`#F5F7FA` light / `#0D1422` dark), causing a white/black transition flash before the first Flutter frame.
   - Legacy splash drawables lived in `drawable-nodpi/` at a fixed 640×640px, causing inconsistent physical sizing across phone densities.

2. **Text Rendering & Layout Root Causes:**
   - **Gujarati Line-Height Clipping:** Inspecting the bundled `assets/fonts/NotoSansGujarati-*.ttf` font metrics showed `UPM=1000`, `winAscent=1076`, `winDescent=408` (natural height ratio `1.484`). `AppTypography` previously enforced tight line heights (`1.2`, `1.25`, `1.3`), clipping Gujarati vowel marks (matras) and descenders inside buttons, chips, badges, inputs, and bottom navigation labels.
   - **Missing Glyph (`→` U+2192) & Missing Fallback:** `NotoSansGujarati` does not include `→` (`0x2192`), which was rendered in rate date ranges (`stock_issue_page.dart`, `worker_detail_page.dart`, `rate_history_page.dart`) without a `fontFamilyFallback`.
   - **Crowded 6-Tab Mobile `NavigationBar`:** Placing 6 destinations (`Dashboard`, `Lots`, `Processes`, `Workers`, `Inventory`, `Business Profile`) into a 360dp bottom bar gave only 60dp per item, clipping longer Gujarati labels.
   - **Silent Truncation & Cramped Rows:** `AppAnimatedNumber` and `AppButton` enforced `maxLines: 1, overflow: TextOverflow.ellipsis` (risking silent truncation of large rupee values and Gujarati action labels). `InventoryOverviewPage` and `ReportsPage` used fixed-width KPI cards (`164dp` / `170dp`) that broke 2-column symmetry on 360dp phones. `LotDetailPage`, `AccountingOverviewPage`, `WorkerLedgerPage`, and `DashboardPage` had non-wrapping rows that compressed titles or overflowed in Gujarati.
   - **Raw Database Enum Strings Leaking to UI:** `RETURN_GOOD`, `RECEIVED_GOOD`, `STOCK_MOVEMENT`, `CREATE`, etc., appeared directly in `DashboardPage`, `StockSettlementPage`, `AccountingOverviewPage`, `ProcessDetailPage`, and `ReportsPage`.
   - **Stale Dropdown Value Sync:** `AppDropdown` relied on `DropdownButtonFormField.initialValue` without a synchronizing key, risking stale visual selection when process/worker lists updated programmatically.

3. **Fragmented Settings & Missing Help:**
   - Theme & Language lived at the bottom of `DashboardPage`; Business Profile was a separate bottom tab; Backup & Restore was duplicated in three places; Process-level billing overrides had no central view; Help & Guidance and About screens did not exist.

4. **High-Friction Stock Issue & Receive Return Workflows:**
   - `StockIssuePage` used a single flat dropdown listing all colours with no search, no in-stock filter, no billing-mode/labour preview, no compact confirmation summary, and popped immediately on save without showing updated available stock or an "Issue More Stock" shortcut.
   - `StockSettlementPage` lacked a dedicated searchable/filterable Pending Issue picker, live remaining pending indicator, Lost vs. Shortage distinction helpers, live stock/labour consequences summary, and post-save next actions (such as issuing returned good stock straight to the next process).

---

## 2. Root Causes & Fixes for Text Rendering & Layout

| Area | Root Cause | V1.1 Fix |
| :--- | :--- | :--- |
| `AppTypography` | Tight `1.2–1.35` heights clipped Gujarati matras; incomplete Material 3 text slots; no `fontFamilyFallback` | Calibrated `1.38–1.50` line heights with `TextLeadingDistribution.even`, full M3 `TextTheme`, `fontFamilyFallback: ['NotoSansGujarati', 'Roboto', 'sans-serif']`, and tabular figures |
| Missing `→` glyph | `NotoSansGujarati` lacks `U+2192` | Replaced `'→'` date separators with `'-'` across rate displays and added fallback list |
| `AppSizing` & `AppTheme` | `40dp` buttons & `isDense` `44dp` inputs squeezed touch targets & Gujarati labels | Upgraded to `44dp` padded buttons (`48dp` touch target), `48dp` inputs with comfortable vertical padding, `helperMaxLines: 3`, `errorMaxLines: 3` |
| `AppAnimatedNumber` & `AppMetricTile` | `maxLines: 1` + ellipsis truncated large currency values on 360dp half-width cards | Wrapped numbers in `FittedBox(fit: BoxFit.scaleDown)` with tabular figures so business values never silently truncate |
| `AppButton` & `AppStatusBadge` | Forced single-line clipping of Gujarati labels | Enabled graceful 2-line wrapping (`softWrap: true, maxLines: 2`) with centered layout & tabular badge numerals |
| `AppDropdown` | Programmatic `value` changes did not always visually sync | Added synchronized `ValueKey` + safe membership guard and 2-line menu item wrapping |
| `DomainLabelLocalizer` | Raw DB enums (`RETURN_GOOD`, `RECEIVED_GOOD`, `CREATE`, `stock_movements`) shown in UI | Centralized EN/GU domain & audit label translator used across Dashboard, Stock, Accounting, Processes, and Reports |
| Bottom Navigation | 6 crowded tabs on 360dp phones | Refined mobile `NavigationBar` to **5 spacious tabs** (`Dashboard`, `Lots`, `Stock`, `Workers`, `Settings`) while keeping `Processes`, `Inventory`, `Labour & Payments`, and `Reports` 1 tap away |

---

## 3. Screens Improved

All 17 application screens were audited and updated for 360dp mobile, tablet, and desktop responsiveness in both English & Gujarati and Light & Dark themes:

1. **Dashboard** (`dashboard_page.dart`) — Removed duplicate theme/language & backup clutter; added daily-work Quick Actions (`Issue Stock`, `Receive Return`, `Stock Movements`, `Labour & Payments`, `Processes`, `Inventory`, `Reports`); localized audit activity; responsive wrapping on pending rows.
2. **Lots & Lot Detail** (`lot_list_page.dart`, `lot_detail_page.dart`) — Fixed narrow-screen header wrapping for Lot Photos and Design actions; tabular prices/quantities; proper `TextEditingController` disposal in all modal sheets.
3. **Inventory Overview** (`inventory_overview_page.dart`) — Replaced fixed `164dp` cards with responsive 2/4-column `AppMetricTile` grid; replaced outdated milestone note; replaced clipping `SegmentedButton` with wrapping `ChoiceChip`s; fixed mobile card `Expanded` wrapping; added standalone `AppBar` support (`/inventory`).
4. **Processes & Process Detail** (`process_list_page.dart`, `process_detail_page.dart`, `process_form_page.dart`) — Added standalone `/processes` route support and localized audit history action labels.
5. **Workers, Assignments & Historical Rates** (`worker_list_page.dart`, `worker_detail_page.dart`, `worker_assignments_page.dart`, `rate_history_page.dart`, `rate_form_page.dart`) — Replaced missing `→` glyph, fixed rate badge wrapping, synchronized dropdowns.
6. **Stock Movements** (`stock_movements_page.dart`) — Daily-work hub supporting both embedded bottom-tab mode and standalone route mode with top Issue/Return/Repair bar and prioritized tabs (`Pending Returns`, `Live Stock`, `Movement History`, `Worker & Process`).
7. **Issue Stock** (`stock_issue_page.dart`) — Redesigned 4-step single-flow + Step 5 Success screen.
8. **Receive Return** (`receive_return_picker_page.dart`, `stock_settlement_page.dart`) — Redesigned Pending Issue picker + live validation + consequences summary + Step 5 Next-Action screen.
9. **Damaged Stock Repair** (`damaged_repair_page.dart`) — Inherited upgraded `AppDropdown`, `AppTextField`, and typography.
10. **Labour & Payments / Worker Ledger** (`accounting_overview_page.dart`, `worker_ledger_page.dart`, `payment_form_page.dart`, `worker_adjustment_form_page.dart`) — Replaced clipping `SegmentedButton`, fixed 360dp Gujarati worker header & running balance wrapping, localized `LabourBasisType` & `Lot`/`Ref` labels.
11. **Business Reports** (`reports_page.dart`) — Fixed `170dp` fixed-width Stock Summary into responsive 2/3-column grid; localized movement badges in Damaged & Lost and labels in Labour report.
12. **Business Profile** (`business_profile_page.dart`) — Added standalone route `AppBar` mode under Settings, removed duplicate Backup card, upgraded save feedback to `AppFeedback`, added billing mode explanations.
13. **Backup & Restore** (`backup_restore_page.dart`) — Reused cleanly inside Settings -> Backup & Data Safety (preserving `/backup` alias).
14. **Centralized Settings, Appearance, Stock & Labour, Help & Guidance (15 topics), and About StitchFlow** (`lib/features/settings/`).

---

## 4. Branded StitchFlow Splash Screen & Launcher Icon Configuration

### Brand Identity Preserved
- **Name:** StitchFlow (`StitchFlow Dev` for dev flavor)
- **Tagline:** *From Fabric to Finished.*
- **Palette:** Deep Navy `#172B4D`, Teal `#0D9488`, Amber `#F4A340`, Soft White `#F5F7FA`, Dark Surface `#0D1422`
- **Logo:** Official Thread S symbol (`assets/branding/logo/stitchflow_symbol.png`)

### Android Native Configuration
- **Android 12+ (API 31+):**
  - `android/app/src/main/res/values-v31/styles.xml` (Light):
    - `android:windowSplashScreenBackground` = `@color/splash_background_light` (`#F5F7FA`)
    - `android:windowSplashScreenAnimatedIcon` = `@drawable/splash_icon_android12` (Thread S centered strictly inside the 160dp/288dp circular safe zone across `mdpi`–`xxxhdpi`)
    - `android:windowSplashScreenBrandingImage` = `@drawable/splash_branding_light` (`200dp × 80dp` wordmark + tagline)
  - `android/app/src/main/res/values-night-v31/styles.xml` (Dark):
    - `android:windowSplashScreenBackground` = `@color/splash_background_dark` (`#172B4D`)
    - `android:windowSplashScreenAnimatedIcon` = `@drawable/splash_icon_android12`
    - `android:windowSplashScreenBrandingImage` = `@drawable/splash_branding_dark`
- **Android Legacy (API 21–30):**
  - Fixed `android/app/src/main/res/drawable-v21/launch_background.xml` (previously blank) and added `drawable-night-v21/launch_background.xml`.
  - Replaced unscaled `drawable-nodpi/splash_brand_*.png` with density-bucketed `220dp` drawables in `drawable-mdpi`, `drawable-hdpi`, `drawable-xhdpi`, `drawable-xxhdpi`, and `drawable-xxxhdpi`.
- **Zero White/Black Flash:**
  - `NormalTheme` in `values/styles.xml` and `values-night/styles.xml` uses `@color/normal_background_light` (`#F5F7FA`) and `@color/normal_background_dark` (`#0D1422`), matching Flutter's `AppTheme` scaffold colors.
  - Zero artificial splash timers or delays; `bootstrap()` runs fast local init and renders the first frame immediately.
- **Launcher Icon (Verified Separately):**
  - Adaptive icon `mipmap-anydpi-v26/ic_launcher.xml` uses `@color/ic_launcher_background` (`#172B4D`), `@drawable/ic_launcher_foreground`, and `@drawable/ic_launcher_monochrome`, alongside full legacy `mipmap-mdpi`..`xxxhdpi/ic_launcher.png`.
- **Flavors (`dev` & `prod`):**
  - Both flavors inherit the branded splash and launcher icons from `src/main/res`, with isolated IDs (`com.brijesh.stitchflow.dev` / `com.brijesh.stitchflow`) and app labels (`StitchFlow Dev` / `StitchFlow`).
- **Web (`web/index.html`):**
  - Added light/dark CSS body background (`#F5F7FA` / `#172B4D`) matching the native launch surface.

---

## 5. Centralized Settings & Help Architecture

Implemented under `lib/features/settings/`:

- **`SettingsHomePage`** (`/settings` and 5th primary shell tab): Mobile-first grouped hub with live badges and clean sub-navigation:
  - **A. Appearance** (`/settings/appearance` — `AppearanceSettingsPage`): Theme (System / Light / Dark) + Language (System / English / ગુજરાતી) backed by existing `ThemeCubit` & `LocaleCubit`, plus live bilingual readability & semantic badge preview.
  - **B. Business Profile** (`/settings/business-profile`): Reuses existing `BusinessProfilePage(showAppBar: true)` backed by the single `business_profile` table.
  - **C. Stock & Labour Preferences** (`/settings/stock-labour` — `StockLabourSettingsPage`): Configures global default billing mode via `BusinessProfileRepository` with clear explanations, and lists every process showing whether it **Inherits Global Default** or **Overrides**, plus **Damaged Included / Excluded** status, with 1-tap edit navigation.
  - **D. Backup & Data Safety** (`/settings/backup`, keeping `/backup` alias): Reuses `BackupRestorePage` (full `.zip` backup, verified atomic restore with destructive warning, raw `.sqlite` inspection export).
  - **E. Help & Guidance** (`/settings/help` & `/settings/help/:topicId` — `HelpGuidancePage`, `HelpTopicDetailPage`, `StitchFlowHelpCatalog`): Searchable guide covering all **15 workshop topics** in simple **English and Gujarati**, each with *When to Use*, numbered *Step-by-Step Guide* cards, and a *Practical Workshop Example*.
  - **F. About StitchFlow** (`/settings/about` — `AboutStitchFlowPage`): Official branding, version `1.1.0 (Build 2)`, active flavor, local database filename, offline privacy explanation, and Open-Source Licenses viewer.

---

## 6. Stock Issue & Receive Return UX Redesign

All existing calculators (`StockCalculator`, `LabourCalculator`, `MemberProcessRateResolver`), repository transactions (`StockMovementRepositoryImpl`), database tables, and `clientRequestId` idempotency guards remain 100% authoritative and unchanged.

### Redesigned Stock Issue (`StockIssuePage`)
- **Step 1 — Select Stock:** Searchable in-page stock selector with `In Stock Only` filter (default ON), showing Lot, Design, Colour, and green Available Good Qty badge; collapses into a crisp summary card with `Change` button once selected.
- **Step 2 — Select Work:** Tap-friendly Active Process chips and Eligible Assigned Worker chips, live Locked Rate & Effective Billing Mode preview card, plus collapsible advanced drawer for IST Date/Time, Notes, and Audited Rate Override.
- **Step 3 — Enter Quantity:** Large high-contrast tabular numeric field with quick-fill chips (`+10`, `+25`, `+50`, `All Available`) and immediate live over-stock validation.
- **Step 4 — Confirm Issue:** Compact summary card showing stock, process, worker, quantity, locked rate, billing mode, IST timestamp, and estimated labour, with a single idempotent `Confirm & Issue Stock` action.
- **Step 5 — Success:** Displays issue summary, freshly queried **Updated Available Good Stock**, and one-tap actions (`Issue More Stock` with fresh `clientRequestId`, `View Issue / Receive Return`, `Done`).

### Redesigned Receive Return (`ReceiveReturnPickerPage` & `StockSettlementPage`)
- **Step 1 — Select Pending Issue:** Searchable & Worker/Process-filterable list of open issues showing Worker, Process, Lot/Design/Colour, Issued, Previously Returned, Remaining Pending (amber), Locked Rate, and IST Date.
- **Step 2 — Enter Return Quantities:** Live dynamic **Remaining Pending After Save** bar (green at 0, amber if partial, red error banner if over-return), 1-tap `All Good` shortcut, color-coded Good / Damaged / Lost / Shortage inputs with helper explanations distinguishing Lost vs. Shortage, and mandatory Reason enforcement whenever `Damaged + Lost + Shortage > 0`.
- **Step 3 — Explain Consequences:** Live preview card showing exact stock movements (in-house good, damaged bucket, lost, shortage, remaining pending) and exact payable labour computed via `LabourCalculator` using the issue's locked configuration.
- **Step 4 — Confirm & Save:** Single double-submit-protected atomic transaction with idempotent `clientRequestId`.
- **Step 5 — Next Action:** Shows updated pending (`Fully Settled` badge at 0), earned labour, and shortcuts to **Issue Returned Stock to Next Process** (pre-selecting that colour), **Receive Another Return**, **View Issue Details**, or **Done**.

---

## 7. Packages Changed

- **Zero new third-party packages added.** Existing Flutter `3.50.1`, Dart `3.14.0`, and `material_ui: ^1.11.1` dependencies were preserved unchanged.
- `pubspec.yaml` version incremented from `1.0.0+1` to `1.1.0+2`.
- Added 112 new bilingual EN/GU localization keys (`0` untranslated keys across `app_en.arb` and `app_gu.arb`).

---

## 8. Verification, Tests & Build Results

All commands below were actually executed and verified after the final code changes:

| Check | Command | Result |
| :--- | :--- | :--- |
| Dependencies | `flutter pub get` | Passed |
| Formatting | `dart format .` | Passed (0 unformatted files) |
| Localization | `flutter gen-l10n` | Passed (0 untranslated keys) |
| Codegen | `dart run build_runner build` | Passed (259 outputs) |
| Static Analysis | `flutter analyze` | **0 issues found** |
| Automated Test Suite | `flutter test` | **77 / 77 tests passed** (includes database integrity, v1→v2 migration, stock/labour/ledger calculators, E2E 18-step workflow, backup/restore, splash/flavor resource checks, Settings & Help navigation/persistence, 360dp EN/GU Light/Dark zero-overflow tests, redesigned Stock Issue & Receive Return validation/partial/full/reason/idempotency tests) |
| Dev Debug APK | `.\build_apk.bat dev debug` | **Succeeded** — `build/releases/dev/StitchFlow_Dev_20261123_152641_debug.apk` (173.48 MB) |
| Prod Debug APK | `.\build_apk.bat prod debug` | **Succeeded** — `build/releases/prod/StitchFlow_Prod_20261123_152738_debug.apk` (173.48 MB) |
| Prod Release APK | `.\build_apk.bat prod` | **Succeeded** — `build/releases/prod/StitchFlow_Prod_20261123_153041.apk` (69.34 MB) |

---

## 9. Known Issues & Notes

- **Android Release Signing:** As in V1, `android/app/build.gradle.kts` still uses debug signing config for local sideloadable release APKs until a production release keystore is configured.
- **iOS Storyboard Launch Image:** iOS `LaunchScreen.storyboard` retains its default template (`LaunchImage`); Android (primary garment workshop target) and Web were fully updated in V1.1.
- **On-Device Visual Verification:** Automated widget tests verified zero `RenderFlex` overflows at `360dp`, `390dp`, `800dp`, and `1280dp` in EN & GU and Light & Dark modes, and verified all Android splash XML/PNG resources; final physical-device checks should follow Section 10 below.

---

## 10. Manual Android Testing Instructions

Install `build/releases/prod/StitchFlow_Prod_20261123_153041.apk` (or `StitchFlow_Dev_20261123_152641_debug.apk` side-by-side) on a real Android 12+ phone (and optionally an Android 10/11 device):

1. **Splash Screen & Launcher Icon:**
   - Verify the home screen icon shows the Deep Navy rounded-square **Thread S** icon (`StitchFlow` / `StitchFlow Dev`).
   - Cold-launch the app in **Light Mode**: confirm soft white `#F5F7FA` background, centered unclipped Thread S icon, `StitchFlow / From Fabric to Finished.` branding, and smooth transition into the Dashboard with no black/white flash.
   - Switch Android system theme to **Dark Mode** and cold-launch: confirm Deep Navy `#172B4D` splash background with white/amber wordmark transitioning smoothly into Dark Mode.
2. **Typography & Gujarati Rendering:**
   - Open **Settings -> Appearance**, switch to **ગુજરાતી (Gujarati)** and test both Light & Dark themes.
   - Check Dashboard, Lots, Stock, Workers, Settings, Labour & Payments, and Reports: confirm Gujarati matras (`િ`, `ુ`, `ૂ`, `ે`, `ો`, `ં`) are crisp and unclipped, numbers align cleanly, and no button or bottom tab overflows.
3. **Centralized Settings & 15-Topic Help:**
   - Verify all 6 Settings sections open cleanly with consistent back navigation.
   - Open **Stock & Labour Preferences**, toggle global billing mode, and verify process override badges match Process settings.
   - Open **Help & Guidance**, search in English and Gujarati, and open several topics to verify step cards and examples.
4. **Stock Issue & Receive Return Daily Flow:**
   - Tap **Issue Stock**, search/select a colour, tap Process & Worker chips, verify locked rate & billing preview, try exceeding available stock (confirm immediate error), enter valid qty, review confirmation summary, tap **Confirm & Issue Stock**, verify updated available stock on Success screen, and test **Issue More Stock**.
   - Tap **Receive Return**, filter pending issues, enter a partial Good return (check live remaining pending & labour impact), save, then receive remaining pieces with Damaged + Lost + Shortage (verify mandatory reason validation), save, and tap **Issue Returned Stock to Next Process**.
5. **Backup & Data Continuity:**
   - Confirm existing V1 SQLite data remains intact after installing V1.1 over V1, and test creating a `.zip` backup in **Settings -> Backup & Data Safety**.
