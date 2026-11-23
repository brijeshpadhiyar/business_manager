# StitchFlow V1.2 — Executive Plan

**Target Release:** `1.2.0+3`  
**Status:** Planning Stage (Milestone 12.0 — Pending Owner Approval)  
**Verified Baseline:** StitchFlow V1.1 (`1.1.0+2`) on Flutter `3.50.1` (`stable`), Dart `3.14.0`, `material_ui: ^1.11.1`, Drift `2.35.3` / SQLite `3.9.1` (schema v2), `flutter analyze` = 0 issues, `flutter test` = 77 / 77 passing, 507 EN & GU localization keys (0 untranslated).  
**Planning Date:** `2026-11-23` (`Asia/Kolkata`)

---

## 1. Product Vision & User Persona

StitchFlow V1.2 is built for a **single-owner garment workshop** operated primarily on an **Android smartphone** by the owner's father. Every design decision prioritizes:

1. **Zero-Friction Daily Operations:** Fast, thumb-friendly workflows on 360dp Android screens in **Gujarati (`ગુજરાતી`)** and **English**, with Light, Dark, and System themes.
2. **100% Offline Sovereignty:** All operational, financial, reporting, security, and notification capabilities run completely offline on-device with zero mandatory internet dependency.
3. **Practical Local Privacy:** Protecting workshop stock, karigar rates, and ledger balances from casual physical access without turning StitchFlow into a complex login/account app.
4. **Accounting & Inventory Integrity:** Preserving 100% of StitchFlow's immutable append-only ledger, locked historical rates, chronological reversal guards, atomic SQLite transactions, and `Asia/Kolkata` (IST) business-date semantics.

---

## 2. Scope & Strict Non-Goals

### In Scope for V1.2
| Phase | Capability | Core Deliverables |
| :--- | :--- | :--- |
| **Phase A** | **Local Application Security** | Optional/recommended 4–6 digit local PIN (salted PBKDF2-HMAC-SHA256 in Android Keystore via `flutter_secure_storage`), automatic lock on background/timeout/restart, manual Lock Now, privacy shield + `FLAG_SECURE`, optional Android biometric unlock (`local_auth` v3 + `FlutterFragmentActivity`), offline recovery key, sensitive-action re-auth. |
| **Phase B** | **Faster Daily Workshop Operations** | Today-focused Workshop Dashboard strip, important/oldest pending work alerts, Daily Production Summary screen, Quick Issue recent suggestions & unusual-action confirmation, Quick Return oldest-first sorting & quantity shortcuts, live Worker Work & Balance overview on `WorkerDetailPage`. |
| **Phase C** | **Advanced Reports & Business Insights** | 6 unified report categories (Daily Workshop, Worker Performance, Process Performance incl. reliable turnaround time, Inventory, Labour & Financial, Business Insights & period comparisons), IST preset + dimension filters, single-pass `ReportsAnalyticsCalculator`, Gujarati-safe offline Print/PDF export (Android WebView + `PrintManager`) and MIT-licensed Excel (`.xlsx`) + UTF-8 BOM `.csv` export. |
| **Phase D** | **Local Android Notifications** | 100% offline local reminders (`flutter_local_notifications`) for Pending Work, Worker Settlement, Daily Workshop Summary, Backup Reminder, and Important Local Alerts; Android 13+ runtime permission handling; battery-friendly `inexactAllowWhileIdle`; reboot survival; auto-cancellation when work is settled; lock-safe deep links. |

### Strictly Excluded from V1.2 (Non-Negotiable)
- **NO** user registration, cloud authentication, or email/password login.
- **NO** multiple user accounts, staff login, or Admin/Manager/Worker roles (RBAC).
- **NO** Firebase Auth, Firebase Cloud Messaging (FCM), Supabase, or cloud backend/database.
- **NO** silent stock/financial mutations, fabricated revenue/profit figures, or database resets.
- **NO** replacement of `material_ui: ^1.11.1`, `flutter_bloc`, `drift`, `go_router`, or `get_it`/`injectable`.

---

## 3. Verified Baseline Summary (From Repository Inspection)

Every baseline item reported in V1.1 was verified directly against `C:\A1\business_manager` on `2026-11-23`:

- **Flutter / Dart:** Verified `Flutter 3.50.1` (`stable`), `Dart 3.14.0`, `pubspec.yaml` version `1.1.0+2`.
- **UI Foundation:** `material_ui: ^1.11.1` preserved across centralized `lib/core/widgets/` and StitchFlow brand tokens (`#172B4D`, `#0D9488`, `#F4A340`, `#F5F7FA`, `#0D1422`, `NotoSansGujarati`).
- **Database:** Drift `^2.35.3` + `sqlite3: ^3.9.1`, `schemaVersion = 2`, 14 tables, 8 DAOs, `WAL` + `synchronous = FULL` + `foreign_keys = ON` + `busy_timeout = 5000`.
- **Flavors & Builds:** `dev` (`com.brijesh.stitchflow.dev` / `business_manager_dev.sqlite`) and `prod` (`com.brijesh.stitchflow` / `business_manager_prod.sqlite`), automated via `build_apk.bat` -> `scripts/build_apk.ps1`.
- **Localization:** 507 keys in `lib/l10n/app_en.arb` and 507 keys in `lib/l10n/app_gu.arb` (`l10n_untranslated.txt = {}`).
- **Static Analysis & Tests:** `flutter analyze` passed with **0 issues**; `flutter test` passed with **77 / 77 tests** (note: audit found 1 verbatim duplicate migration test in `test/database/app_database_persistence_migration_test.dart`, which will be cleaned up in V1.2).
- **Audit Gaps Identified for V1.2 Cleanup:**
  1. `MainActivity.kt` currently extends `FlutterActivity` (must change to `FlutterFragmentActivity` for `local_auth` v3 Android `BiometricPrompt`).
  2. `AndroidManifest.xml` does not explicitly set `android:allowBackup="false"` (required to prevent Android Keystore key-wrapping errors with `flutter_secure_storage` v10).
  3. `android/app/build.gradle.kts` does not yet enable `isCoreLibraryDesugaringEnabled = true` (required for `flutter_local_notifications`).
  4. `NativeBackupRestoreService.appVersionString` is still hardcoded to `'1.0.0+1'` instead of reading `AppIdentity`.
  5. `ReportsRepositoryImpl.getBusinessReports()` queries `stock_movements` 5 separate times and only applies date ranges to 3 of 10 reports.
  6. `WorkerDetailPage` still omits the worker's live pending stock and financial balance summary.
  7. `DomainLabelLocalizer` does not yet map `BACKUP_EXPORT`, `BACKUP_RESTORE`, `DEACTIVATE`, `REACTIVATE`, `DAMAGED_TO_GOOD_ADJUSTMENT`, or entity `backup`.

Full details are documented in [01_CURRENT_ARCHITECTURE_AUDIT.md](./01_CURRENT_ARCHITECTURE_AUDIT.md).

---

## 4. Key Architecture & Package Decisions

### 4.1 Package Additions (Minimal, Verified Against Flutter 3.50.1 / Dart 3.14.0)

| Package | Proposed Version | Purpose | Official Documentation |
| :--- | :--- | :--- | :--- |
| `flutter_secure_storage` | `^10.3.4` | Android Keystore-backed RSA-OAEP + AES-GCM storage for salted PIN hash, lockout state, and recovery key hash (does **not** use deprecated `EncryptedSharedPreferences`). | [pub.dev/packages/flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| `local_auth` | `^3.0.2` | Official Flutter biometric authentication (`BiometricPrompt` on Android, v3 flat `authenticate()` API & typed `LocalAuthException`). | [pub.dev/packages/local_auth](https://pub.dev/packages/local_auth) |
| `flutter_local_notifications` | `^22.0.0` | Offline local Android notifications, channels, Android 13+ runtime permissions, boot persistence, `inexactAllowWhileIdle` scheduling. | [pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |
| `excel_plus` | `^2.29.3` | Pure Dart, MIT-licensed `.xlsx` workbook generator with full UTF-8 Gujarati/English support and zero commercial license restrictions. *(Alternative: `excel_community: ^2.6.2` if lighter constraints are preferred at implementation time.)* | [pub.dev/packages/excel_plus](https://pub.dev/packages/excel_plus) |

**Explicitly Reused Without Adding Redundant Packages:**
- **PIN Hashing:** Pure Dart **PBKDF2-HMAC-SHA256** (210,000 iterations, 16-byte `Random.secure()` salt, executed in `Isolate.run`) built directly on the **already-installed `crypto: ^3.0.6`** — zero native C/FFI binaries, OWASP-compliant, deterministic across all platforms! *(Alternative: `cryptography: ^2.9.0` Argon2id — evaluated in `02_SECURITY_DESIGN.md`.)*
- **Gujarati-Safe PDF & Print:** Native Android `WebView` + `PrintManager` (`createPrintDocumentAdapter`) via a lightweight ~70-line Kotlin `MethodChannel` in `MainActivity.kt` using the **already-bundled `NotoSansGujarati` font** — guarantees 100% accurate HarfBuzz Gujarati conjunct/matra shaping with zero `harfbuzz_ffi` APK bloat and avoids the deprecated `Printing.convertHtml()`.
- **Time Zones:** Reuses **already-installed `timezone: ^0.11.2`** + `IstDateTimeHelper` (`Asia/Kolkata`).
- **Charts / Trends:** Custom StitchFlow-branded `CustomPainter` sparklines/bar strips inside `lib/core/widgets/` — zero heavy chart package bloat and 100% bilingual/theme control.
- **File Sharing:** Reuses **already-installed `share_plus: ^13.3.1`**.

### 4.2 Database Impact (`v2 -> v3` Index-Only Additive Migration)
- **Zero new tables, zero column alterations, zero data resets.**
- Security credentials live exclusively in Android Keystore (`flutter_secure_storage`) — never inside SQLite or `.zip` backups.
- Notification settings & UI preferences live in flavor-scoped `SharedPreferences`.
- **Schema v3** adds **5 idempotent read-performance indexes** (`CREATE INDEX IF NOT EXISTS`) on `transaction_at` and `audit_logs(action_type, recorded_at)` so date-range reports, trends, today's dashboard, and backup-age checks remain fast at 50,000+ rows.
- V1.0 (`v1`) and V1.1 (`v2`) `.zip` backups remain 100% restorable and automatically upgrade to `v3` during atomic restore verification.

---

## 5. Milestone Roadmap & Dependency Order

| Milestone | Scope | Complexity | Dependencies |
| :--- | :--- | :---: | :--- |
| **12.0** | Architecture Audit & Approved V1.2 Design Docs (this stage) | Complete | None |
| **12.1** | Local PIN, Biometric & App-Lock Security + Privacy Shield + Recovery Key | High | 12.0 approval |
| **12.2** | Daily Workshop Productivity (Today Dashboard, Daily Summary, Quick Issue/Return, Worker Overview) | Medium | 12.1 (Lock Now action + lock-safe nav) |
| **12.3** | Schema v3 Indexes, Advanced Reports, Business Insights & Gujarati-Safe Print/PDF/Excel Export | High | 12.2 (shares Daily Summary & IST range presets) |
| **12.4** | Local Android Notifications & Settings | Medium | 12.1 (lock-safe deep links), 12.2 (`/daily-summary`), 12.3 (indexed audit/report queries) |
| **12.5** | Full QA, Migration/Backup Verification, Bilingual 360dp Polish & Release APKs (`1.2.0+3`) | Medium | 12.1–12.4 |

**Why this order is optimal:** Starting with **12.1 (Security)** establishes `FlutterFragmentActivity` and `AppLockGate` early so every subsequent screen, export action, and notification deep-link automatically inherits lock protection. **12.2 (Workshop UX)** establishes IST "Today" helpers and `/daily-summary` reused by **12.3 (Reports)** and **12.4 (Notifications)**. Placing the index-only `v2 -> v3` migration at the start of **12.3** speeds up both Reports and Notification queries before final end-to-end verification in **12.5**.

---

## 6. Decisions Requiring Owner Approval Before Milestone 12.1

Please confirm the following product/engineering decisions before code implementation starts:

1. **PIN Format & Opt-In Default:**
   - *Proposal:* App Lock is **off by default on upgrade from V1.1** (never locking out the user unexpectedly after updating), with a non-intrusive banner/card in Settings -> Security to enable a **4-digit (default) or 6-digit numeric PIN** plus optional fingerprint unlock. Confirm?
2. **Default Auto-Lock Timeout:**
   - *Proposal:* Lock after **1 minute** in background (configurable: Immediate, 30s, 1 min, 5 min, 15 min) + always lock on cold app restart + manual "Lock Now" button. Confirm?
3. **PIN Recovery Policy:**
   - *Proposal:* Generate an offline **8-character Recovery Key** (`XXXX-XXXX`) once at PIN creation for the owner to write down safely. If both PIN and Recovery Key are lost, there is **no silent bypass** (only restoring a prior `.zip` backup after clearing app data). Confirm?
4. **Screenshots & Recent Apps (`FLAG_SECURE`):**
   - *Proposal:* Always mask Recent Apps previews via a StitchFlow privacy shield and enable `FLAG_SECURE` on Lock/PIN screens; provide a Settings toggle (default **ON** when PIN is enabled) to block screenshots across the whole app, which the owner can turn OFF if they need to screenshot a worker ledger for WhatsApp. Confirm?
5. **PDF & Print Strategy for Gujarati:**
   - *Proposal:* Use native Android `WebView` + `PrintManager` (bundled `NotoSansGujarati`, 100% accurate Gujarati shaping, supports both Print and "Save as PDF") + MIT-licensed `.xlsx` & `.csv` export for WhatsApp/Excel sharing. Confirm whether native "Print / Save as PDF" is sufficient or if you also require 1-tap direct `.pdf` file sharing to WhatsApp (which adds an Android `PdfDocument` wrapper).
6. **Database Schema v2 -> v3 Index-Only Migration:**
   - *Proposal:* Approve additive index-only migration (`schemaVersion = 3`, zero table/column changes, 100% compatible with V1.0/V1.1 backups) to accelerate date-filtered reports and backup-age notification checks. Confirm?
7. **Notification Defaults:**
   - *Proposal:* Use battery-friendly `inexactAllowWhileIdle` (no invasive Exact Alarm system prompt), opt-in Android 13+ permission request from Settings -> Notifications (never spamming permission popups on first launch), and sensible defaults (Pending Work > 3 days @ 10:00 AM, Weekly Settlement Saturday @ 6:00 PM, Daily Summary @ 8:00 PM, Backup Reminder every 7 days @ 8:30 PM). Confirm?

---

## 7. Document Index

1. [00_V1_2_EXECUTIVE_PLAN.md](./00_V1_2_EXECUTIVE_PLAN.md) — Executive summary, scope, decisions, roadmap.
2. [01_CURRENT_ARCHITECTURE_AUDIT.md](./01_CURRENT_ARCHITECTURE_AUDIT.md) — Verified repository & codebase audit.
3. [02_SECURITY_DESIGN.md](./02_SECURITY_DESIGN.md) — Local PIN, biometrics, app lock, recovery, threat model.
4. [03_WORKSHOP_UX_PLAN.md](./03_WORKSHOP_UX_PLAN.md) — Dashboard, Quick Issue, Quick Return, Daily Summary & Worker Overview.
5. [04_REPORTS_AND_INSIGHTS_DESIGN.md](./04_REPORTS_AND_INSIGHTS_DESIGN.md) — 6 report categories, formulas, insights, filters, Gujarati-safe PDF/Print/Excel export.
6. [05_NOTIFICATIONS_DESIGN.md](./05_NOTIFICATIONS_DESIGN.md) — Offline Android notifications, channels, permissions, dedupe, deep links.
7. [06_DATABASE_AND_MIGRATION_PLAN.md](./06_DATABASE_AND_MIGRATION_PLAN.md) — Schema v2 -> v3 index-only migration, safety & backup compatibility.
8. [07_TESTING_AND_RELEASE_PLAN.md](./07_TESTING_AND_RELEASE_PLAN.md) — Automated QA matrix, physical Android verification & release playbook.
9. [08_PHASED_IMPLEMENTATION_TASKS.md](./08_PHASED_IMPLEMENTATION_TASKS.md) — Dependency-ordered engineering backlog for Milestones 12.0–12.5.
