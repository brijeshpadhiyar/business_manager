# 05 — Local Android Notifications Design (Phase D)

**Objective:** Deliver reliable, non-spammy, 100% offline local Android reminders that help the workshop owner stay on top of pending karigar work, worker settlements, evening summaries, and backups — with **zero Firebase, zero FCM, and zero backend servers**.

---

## 1. Package & Android API Research (Verified Latest Standards)

### 1.1 Package Choice
- **`flutter_local_notifications: ^22.0.0`** (official community standard, actively maintained, full Android 13/14/15 support, boot receiver included).
- **`timezone: ^0.11.2`** — **already installed in `pubspec.yaml`** and initialized in `IstDateTimeHelper.initialize()` (`Asia/Kolkata`). Zero extra timezone package required because StitchFlow schedules business reminders in `Asia/Kolkata` (`IstDateTimeHelper.istLocation`)! *(Note: verify exact `flutter_local_notifications` version constraint against `timezone: ^0.11.2` during `flutter pub add` in Milestone 12.4; pin compatible major version if needed.)*

### 1.2 Mandatory Android Native Configuration
1. **Core Library Desugaring (`android/app/build.gradle.kts`):**
   ```kotlin
   compileOptions {
       isCoreLibraryDesugaringEnabled = true
       sourceCompatibility = JavaVersion.VERSION_17
       targetCompatibility = JavaVersion.VERSION_17
   }
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   }
   ```
   *(Required by `flutter_local_notifications` for Java `java.time` APIs on Android < 8 / backwards compatibility.)*
2. **`android/app/src/main/AndroidManifest.xml`:**
   ```xml
   <!-- Android 13+ (API 33+) runtime notification permission -->
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   <!-- Re-register scheduled notifications after device reboot or app update -->
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
   ```
   Inside `<application>`:
   ```xml
   <receiver
       android:exported="false"
       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
   <receiver
       android:exported="false"
       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
       <intent-filter>
           <action android:name="android.intent.action.BOOT_COMPLETED" />
           <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
           <action android:name="android.intent.action.QUICKBOOT_POWERON" />
           <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
       </intent-filter>
   </receiver>
   ```
   *(Notice `android:exported="false"` on both receivers — secure best practice for system-only broadcast intents on Android 12+!)*
3. **Scheduling Mode Decision (`inexactAllowWhileIdle` — Deliberate Android 14+ Choice):**
   - We explicitly use **`AndroidScheduleMode.inexactAllowWhileIdle`** and **DO NOT** declare `USE_EXACT_ALARM` or `SCHEDULE_EXACT_ALARM`.
   - **Why:**
     1. Google Play strictly restricts `USE_EXACT_ALARM` to alarm-clock and calendar apps; requesting `SCHEDULE_EXACT_ALARM` on Android 14+ forces users into a confusing system Settings page.
     2. Workshop reminders (10:00 AM pending work check, 8:00 PM daily summary, weekly backup reminder) do **not** require millisecond precision — firing within a 2–10 minute battery-friendly OS window even during Doze mode is ideal and respects Android battery health.

---

## 2. Notification Categories, Channels & Smart Trigger Rules

Each category has its own Android `NotificationChannel` (allowing OS-level sound/vibration control) and a **deterministic integer Notification ID** (eliminating duplicates permanently — scheduling with the same ID atomically replaces the prior pending notification!).

| ID | Channel ID | Category | Default Schedule (IST) | Condition to Schedule / Fire | Auto-Cancel Rule | Deep-Link Payload |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- |
| `1001` | `sf_pending_work` | **Pending Work Reminder** | Daily @ `10:00 AM` (configurable) | Fires ONLY if `>= 1` active open issue has pending age `>= N` days (configurable: `1, 2, 3, 5, 7` days; default `3` days). | Automatically cancelled when all issues are settled or none meet age threshold. | `/stock/return` |
| `1002` | `sf_worker_settlement` | **Worker Settlement Reminder** | Weekly Saturday @ `06:00 PM` (day & time configurable) | Fires ONLY if `>= 1` worker has `outstandingPayablePaise >= threshold` (configurable: `₹100, ₹500, ₹1000, ₹5000`; default `₹500`). | Automatically cancelled when all workers' payable balances drop below threshold. | `/accounting` |
| `1003` | `sf_daily_summary` | **Daily Workshop Summary** | Daily @ `08:00 PM` (configurable) | Summarizes today's activity if scheduled today (or reminds to review evening workshop summary). Respects **"Skip if no activity today"** toggle (default `ON` to prevent noise on holidays/Sundays!). | Cancelled if disabled or skipped on quiet day. | `/daily-summary` |
| `1004` | `sf_backup_reminder` | **Backup Reminder** | Every `7` days @ `08:30 PM` (interval `3, 7, 14, 30` days configurable) | Computes `lastBackupAt` from latest `audit_logs` row where `action_type = 'BACKUP_EXPORT'`. Schedules for `lastBackupAt + intervalDays` (or next `08:30 PM` IST if overdue!). | Immediately rescheduled forward by `intervalDays` whenever a `.zip` backup succeeds! | `/settings/backup` |
| `1005` | `sf_business_alerts` | **Important Local Business Alerts** | Evaluated on app open & after stock settlement (cooldown: max 1 alert per 24h per alert key) | Alerts on critical local thresholds: e.g., Damaged stock bucket exceeds configurable limit (default `>= 20` pcs) OR an issue is overdue `>= 14` days. | Auto-clears once damaged stock is repaired or overdue issue is settled; strict 24h dedupe cooldown prevents nagging. | `/stock/repair` or `/stock/return` |

### Bilingual Notification Content
- Notification titles and bodies are generated using the user's active `LocaleCubit` preference (`en` or `gu`; falling back to device locale if `system`), using localized templates from `AppLocalizations`!
- **Privacy on Lock Screen:** When **App Lock (PIN)** is enabled, notification text stays intentionally **high-level and privacy-safe** — e.g., *"3 pending workshop returns need follow-up"* or *"2 workers have pending settlements"* — NEVER leaking exact Rupee amounts, worker names, or rates onto the Android lock screen! (Plus `NotificationVisibility.private` on `AndroidNotificationDetails`!)

---

## 3. Anti-Noise, Deduplication & Re-Evaluation Architecture

Because StitchFlow is 100% offline with no server push, scheduled notifications use a **Reconcile-on-Change** pattern (`NotificationRefreshCoordinator`):

1. **Pure Dart Planner (`NotificationPlanCalculator`):**
   - Takes current `NotificationSettings`, current IST timestamp (`nowUtcMillis`), open pending issues, worker financial summaries, today's activity counts, damaged stock total, and last `BACKUP_EXPORT` timestamp.
   - Outputs an exact, deterministic `List<PlannedLocalNotification>` (only the notifications that SHOULD currently be scheduled) + `Set<int> idsToCancel` (IDs whose underlying condition is now resolved!).
   - **100% pure Dart** — fully unit-testable across time zones, edge cases, settled work, and quiet days!
2. **Idempotent Sync (`LocalNotificationService.syncPlan`):**
   - For each ID in `idsToCancel`, calls `plugin.cancel(id)`.
   - For each planned notification, cancels/replaces that exact ID via `zonedSchedule(..., androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle)` using `tz.TZDateTime` in `IstDateTimeHelper.istLocation`.
   - Stores a lightweight digest (`sf_<flavor>_notif_last_plan_hash`) in `SharedPreferences` so redundant identical reschedules are skipped!
3. **Refresh Triggers (Lightweight, Non-Blocking, Fire-and-Forget):**
   - App startup (`bootstrap` / after DB init, only if permission already granted).
   - App resumed from background.
   - Immediately after any:
     - Stock Issue (`StockMovementRepositoryImpl.issueStock`)
     - Stock Return / Settlement (`recordSettlement`)
     - Damaged Repair (`recordDamagedToGoodAdjustment`)
     - Payment / Adjustment (`recordPayment`, `recordAdjustment`)
     - Full Backup Export (`createFullZipBackup`)
     - Backup Restore (`AppSessionController.reloadSession`)
     - Notification Settings update or Language change (`LocaleCubit`)
   - **Result:** If the father settles Ramesh's last pending return at 9:30 AM, the 10:00 AM Pending Work reminder is **immediately cancelled** — StitchFlow never reminds him about already-finished work!

---

## 4. Android 13+ Permission Handling & Device Settings Respect

1. **No Cold-Launch Permission Spam:** Never pop the Android 13+ `POST_NOTIFICATIONS` dialog unexpectedly on first launch.
2. **Contextual Opt-In:** Show a clear status card in `Settings -> Notifications & Reminders` (and an optional dismissible tip card once the user has active lots/workers):
   - Status badges: **Allowed** (green), **Permission Needed** (amber + 1-tap `Allow Notifications` button calling `requestNotificationsPermission()`), or **Blocked in Phone Settings** (red + clear instructions to enable in Android App Info -> Notifications).
3. **Graceful Degradation:** If OS permission is denied or notifications are toggled OFF in Android Settings (`areNotificationsEnabled() == false`), `LocalNotificationService` silently cancels pending schedules and never throws errors or crashes the app.

---

## 5. Lock-Safe Deep Linking on Notification Tap

When the user taps a StitchFlow notification:
1. Extract the validated route payload (strict allowlist: `/stock/return`, `/stock/repair`, `/accounting`, `/daily-summary`, `/settings/backup` — reject any unknown payload).
2. Check `AppLockCubit.state`:
   - If **unlocked** (or PIN disabled): Navigate immediately via `GoRouter`.
   - If **locked**: Store `pendingNavigationRoute` inside `AppLockCubit`. Show the Lock Screen FIRST. Immediately upon successful PIN/Biometric unlock, consume `pendingNavigationRoute` and navigate to the target screen!
   - **Cold Launch from Notification:** Checked via `getNotificationAppLaunchDetails()` during startup and routed through the exact same lock-safe queue.

---

## 6. Reboot & OEM Limitations (Transparent User Guidance)

- **Reboot Survival:** `ScheduledNotificationBootReceiver` automatically restores scheduled `AlarmManager` entries after phone reboot or APK update (verified on stock Android).
- **Known Android OEM Limitation:** Some Android phone manufacturers (Xiaomi MIUI/HyperOS, Vivo FuntouchOS, Oppo ColorOS, Samsung Deep Sleep) aggressively restrict background receivers after reboot until the user opens the app once.
- **Mitigation:**
  1. Re-sync every notification automatically whenever the app opens or resumes.
  2. Include a clear, friendly English & Gujarati note inside `Settings -> Notifications & Reminders` and `Help & Guidance` explaining how to allow StitchFlow notifications under phone battery settings if reminders are delayed.
- **Flavor Isolation:** `dev` and `prod` have separate Android `applicationId`s (`com.brijesh.stitchflow.dev` vs. `com.brijesh.stitchflow`), so OS channels, pending alarms, and permission states are completely isolated!

---

## 7. Module Structure (`lib/features/notifications/`)

```text
lib/features/notifications/
├── domain/
│   ├── entities/notification_entities.dart           # NotificationSettings, NotificationCategory, PlannedLocalNotification, NotificationPermissionStatus
│   ├── calculators/notification_plan_calculator.dart # Pure Dart deterministic scheduler & condition evaluator
│   └── services/local_notification_service.dart      # Abstract interface (100% mockable in unit/widget tests)
├── data/
│   ├── repositories/notification_settings_repository.dart  # Flavor-prefixed SharedPreferences persistence
│   └── services/
│       ├── flutter_local_notifications_adapter.dart        # Real plugin wrapper (Android channels, permissions, zonedSchedule)
│       └── notification_refresh_coordinator.dart           # Queries live repos -> NotificationPlanCalculator -> syncPlan()
└── presentation/
    ├── bloc/notification_settings_cubit.dart
    └── pages/notification_settings_page.dart               # /settings/notifications screen
```
