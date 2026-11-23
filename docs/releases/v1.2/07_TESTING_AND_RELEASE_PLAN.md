# 07 — Testing, Quality Assurance & Release Plan (StitchFlow V1.2)

**Target Release:** `1.2.0+3`  
**Baseline Verified:** 77 / 77 tests passing (76 unique + 1 duplicate to deduplicate), `flutter analyze` = 0 issues.  
**Quality Rule:** Never report a test, analyzer check, or APK build as passed unless actually executed and inspected after the final edit.

---

## 1. Automated Test Strategy & Matrix

### 1.1 Phase A — Security Tests (`test/features/security/` & `test/widget/security_ui_test.dart`)
| Test Case | Layer | Verification Assertions |
| :--- | :---: | :--- |
| `PinHasher` PBKDF2-HMAC-SHA256 hashing & constant-time verification | Unit | Unique salt per call; valid 4/6-digit PIN passes; wrong PIN fails; tampered hash/salt fails; verifier format `pbkdf2_hmac_sha256$v1$...` never contains plaintext PIN. |
| `RecoveryKeyGenerator` & verifier | Unit | Unambiguous 8-char format (`XXXX-XXXX`), case-insensitive & hyphen-tolerant verification, unique salt per generation. |
| PIN setup, confirm mismatch, change PIN, disable PIN | Unit / Cubit | Mismatch blocks save with localized error; change PIN requires current PIN; disable clears secure storage and writes `app_security` audit log without plaintext secrets. |
| Brute-force exponential lockout persistence | Cubit | 5th wrong PIN triggers 30s lockout; 8th triggers 2m; 10th triggers 5m; recreating `AppLockCubit` (simulating process kill) preserves active lockout timer; valid PIN after cooldown resets counter to 0. |
| App lifecycle & auto-lock transitions | Widget / Cubit | `inactive`/`hidden` shows `PrivacyShieldOverlay`; `paused` -> `resumed` within timeout stays unlocked; `paused` -> `resumed` past timeout locks; immediate (`0s`) locks immediately; backward clock jump (>60s) fails closed; cold start with `pinEnabled = true` starts directly in `locked` state with zero Dashboard widgets rendered! |
| System picker suspension guard | Cubit | `suspendAutoLockDuringSystemPicker()` prevents false lock during `file_picker`/`image_picker`/`share_plus` return within cap, and re-enables immediately after. |
| Biometric unlock flows (mocked `BiometricService`) | Cubit / Widget | Success unlocks & resets failed count; `userCanceled` stays locked & keeps PIN pad focused; `notEnrolled`/`noHardware` gracefully disables toggle & falls back to PIN; `temporaryLockout` shows notice & keeps PIN usable; unexpected exception fails closed. |
| Offline PIN recovery flow | Widget / Cubit | Valid Recovery Key verifies, forces setting a new PIN + fresh Recovery Key, preserves 100% of SQLite lots/workers/ledgers; invalid Recovery Key increments lockout counter. |
| Sensitive action re-auth gate | Widget | When PIN enabled, Restore Backup and Export Raw `.sqlite` require `SecurityReauthDialog` before executing; cancelling dialog aborts action. |

### 1.2 Phase B — Workshop Productivity Tests (`test/features/workshop_daily_test.dart` & `test/widget/workshop_ux_v1_2_test.dart`)
| Test Case | Layer | Verification Assertions |
| :--- | :---: | :--- |
| `WorkshopDailyCalculator` IST day boundary | Unit | Transactions at `23:59 IST` vs `00:01 IST` next day land in exact IST business days; reversed movements/labour/payments excluded; Today's issued, good returned, damaged/lost, labour earned, and payments match DB. |
| Recent suggestions derivation | Unit / Repo | Derives up to 3 active recent `(process, worker)` pairs and in-stock colours; excludes deactivated workers, deactivated processes, unassigned pairs, reversed issues, and out-of-stock colours. |
| Quick Issue unusual-action confirmation & idempotency | Widget | Routine issue submits cleanly in 1 tap; issuing 100% of >=50 available stock or overriding rate shows confirmation dialog; cancelling creates 0 rows; confirming creates 1 row; duplicate `clientRequestId` never double-issues. |
| Quick Return sorting, age badges, shortcuts & invariants | Widget | Default `Oldest First` ordering; route pre-filter `?workerId=&processId=` filters accurately; `Half`, `+10`, `Fill Remaining Good` clamp safely to pending; mandatory reason enforced for damaged/lost/shortage; Step 5 Next-Process chip opens Issue with colour & dynamic process pre-selected. |
| `WorkerDetailPage` Work & Balance Overview | Widget | Displays exact worker pending pieces, open issues with 1-tap `Return`, earned labour, and outstanding payable / advance credit matching `LedgerCalculator`. |
| `DailySummaryPage` (`/daily-summary`) | Widget | Switches `Today` / `Yesterday` / Custom IST date; displays accurate worker activity and empty states cleanly. |

### 1.3 Phase C — Advanced Reports, Insights & Export Tests (`test/features/reports_analytics_test.dart` & `test/widget/reports_v1_2_ui_test.dart`)
| Test Case | Layer | Verification Assertions |
| :--- | :---: | :--- |
| `IstDateRangePresets` | Unit | Verifies exact UTC bounds for `Today`, `Yesterday`, `This Week (Mon–Sun IST)`, `This Month`, `Previous Month` including leap-year Feb and year-boundary Jan->Dec. |
| All 6 report categories accuracy & reversal exclusion | Unit / Repo | Daily Workshop, Worker Performance (with process breakdown), Process Performance (with worker contribution & turnaround time), Inventory, Labour & Financial, Business Insights (trends, bottlenecks, period comparisons). |
| Process Average Completion Time reliability | Unit | Fully settled issue (`10h` and `20h`) -> `15.0h (n=2)`; partially settled issue excluded; reversed settlement excluded; backdated settlement (`t_complete < t_issue`) safely excluded; zero settled issues -> `null` (`N/A`). |
| Cross-check invariants against calculators & ledgers | Integration | Assert: Report Total Available Good == `StockCalculator` sum; Report Total Earned Labour == `LedgerCalculator` sum across all workers; Report Total Outstanding == `AccountingRepository` sum; historical locked rates preserved after rate change! |
| Truthful accounting labels | Widget | Zero occurrences of "Profit", "Sales", or "Revenue" anywhere in EN or GU report screens/exports. |
| Large dataset performance benchmark | Performance Unit | Seed 5,000 stock movements + 3,000 labour entries + 1,000 payments in SQLite; verify single-pass `getAdvancedReports()` completes in `< 500ms` and matches expected totals. |
| Gujarati-safe Export (`ReportHtmlBuilder` + `ExcelCsvExportService`) | Unit | Generated HTML contains `NotoSansGujarati` `@font-face`, escaped strings, accurate bilingual Gujarati labels (`કારીગર`, `મજૂરી`, `સ્ટોક`), and exact totals; generated `.xlsx` (read back via `excel_plus`) and UTF-8 BOM `.csv` preserve Gujarati Unicode strings & exact numeric cells without corruption. |

### 1.4 Phase D — Local Notification Tests (`test/features/notifications_plan_test.dart` & `test/widget/notifications_ui_test.dart`)
| Test Case | Layer | Verification Assertions |
| :--- | :---: | :--- |
| `NotificationPlanCalculator` condition evaluation | Unit | Schedules Pending Work (ID `1001`) only when open issue age >= threshold; cancels `1001` when pending == 0; schedules Settlement (ID `1002`) only when outstanding >= threshold; cancels `1002` when settled; skips Daily Summary (ID `1003`) on quiet day when toggle ON; schedules Backup Reminder (ID `1004`) based on latest `BACKUP_EXPORT` audit row and pushes forward N days after backup! |
| Deduplication & cooldown | Unit | Identical plan produces same plan hash (zero redundant reschedule calls); Business Alert (ID `1005`) respects 24h cooldown. |
| IST time zone scheduling | Unit | Scheduled `TZDateTime` values strictly use `Asia/Kolkata` and roll over cleanly to next day/week if configured wall-clock time already passed today. |
| Permission granted vs. denied handling | Cubit / Widget | Mocked `LocalNotificationService`: denied permission shows amber/red banner and schedules 0 alarms without error; granted permission persists settings & triggers sync. |
| Lock-safe notification deep-link | Widget | Tapping notification payload `/accounting` while `AppLockCubit` is `locked` holds navigation until valid PIN is entered, then opens `/accounting` immediately after unlock! |
| Privacy-safe lock screen text | Unit | When `pinEnabled == true`, notification bodies omit exact `₹` rupee figures and worker names. |

### 1.5 Database & Backup Compatibility Tests (`test/database/app_database_persistence_migration_test.dart` & `test/features/end_to_end_business_workflow_test.dart`)
- **Clean up duplicate test** in `app_database_persistence_migration_test.dart`.
- **Add `v1 -> v3` and `v2 -> v3` file-backed migration tests:** Create real v1 and v2 SQLite files on disk with lots, designs, colours, processes, workers, rates, movements, labour, payments, adjustments, and audit logs -> reopen with `AppDatabase` (`schemaVersion = 3`) -> verify all 5 v3 indexes exist in `sqlite_master`, `PRAGMA integrity_check = ok`, `foreign_keys = ON`, `WAL`, `synchronous = FULL`, and 100% of rows are preserved.
- **Cross-version Backup/Restore test:** Restore a V1.1 (`schemaVersion = 2`) `.zip` backup into V1.2 (`schemaVersion = 3`), verify auto-upgrade + `manifest.appVersion == '1.2.0+3'` on new exports + active PIN in `SecureStorage` remains intact across restore!

### 1.6 UI, Responsive & Localization Matrix (`test/widget/`)
Every new/updated V1.2 screen tested across:
- **Viewports:** `360×800` (small Android phone), `800×1024` (tablet), `1280×800` (desktop).
- **Locales:** English (`en`) and Gujarati (`gu`) — verifying `0` untranslated keys (`l10n_untranslated.txt = {}`) and zero `RenderFlex` overflow exceptions (`expect(tester.takeException(), isNull)`).
- **Themes:** Light (`#F5F7FA`) and Dark (`#0D1422`).
- **Accessibility:** Minimum `48dp` interactive touch targets on PIN keypad, quick actions, filter chips, and switches.

---

## 2. Mandatory Pre-Release Verification Commands

Executed in order after final Milestone 12.5 edits (all must pass with exit code `0`):

```powershell
dart format .
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
.\build_apk.bat dev debug
.\build_apk.bat prod debug
.\build_apk.bat dev
.\build_apk.bat prod
```

---

## 3. Physical Android Device Manual QA Checklist

Before handing V1.2 Production APK to the workshop owner's father:

1. **Upgrade Continuity:** Install `StitchFlow_Prod` V1.2 (`1.2.0+3`) directly **over** existing V1.1 (`1.1.0+2`) — verify zero data loss, all lots/workers/balances intact, and App Lock starts cleanly OFF until enabled.
2. **PIN, Biometrics & Lock Lifecycle:**
   - Enable 4-digit PIN, write down 8-char Recovery Key, enable Fingerprint.
   - Background app -> open Android Recent Apps switcher -> confirm workshop numbers are hidden (Privacy Shield / blank preview).
   - Wait past timeout (or tap Lock Now) -> reopen -> verify zero Dashboard flash before Lock Screen.
   - Test Fingerprint cancel -> confirm PIN keypad works immediately and app does NOT bypass lock.
   - Test 5 wrong PINs -> force-close app -> reopen -> confirm 30s lockout timer persisted!
   - Test Forgot PIN -> enter written Recovery Key -> set new PIN -> verify all workshop data intact.
3. **Daily Workshop Speed:**
   - Check Today's Workshop Dashboard, open Daily Summary (`Today` / `Yesterday`), issue stock using 1-tap Recent `(Process, Worker)` chip, test 100% stock confirmation dialog, receive return using `Oldest First` + `Fill Remaining Good`, check Worker Detail live pending & balance card.
4. **Reports & Gujarati Export/Print:**
   - Switch app to **ગુજરાતી**, open all 6 Report Categories, test `This Month` vs `Previous Month` Insights, tap **Print / Save as PDF** -> visually inspect Gujarati conjuncts & matras (`કારીગર`, `પ્રક્રિયા`, `મજૂરી`, `સ્ટોક`, `હિસાબ`) in Android Print Preview -> save PDF.
   - Tap **Export Excel (.xlsx)** -> open in Google Sheets / Microsoft Excel -> confirm Gujarati text and ₹ currency columns render cleanly.
5. **Local Notifications (Android 13/14/15):**
   - Open `Settings -> Notifications`, grant Android 13+ permission, tap `Send Test Notification`, tap notification while app is **locked** -> confirm PIN prompt appears first, then lands on target screen!
   - Reboot phone -> verify scheduled reminders persist cleanly.
6. **Backup & Restore Safety:**
   - Create V1.2 `.zip` backup (confirm PIN re-auth prompt for Raw SQLite export & Restore), verify Backup Reminder reschedules forward by 7 days, restore backup and confirm PIN remains active and intact.
