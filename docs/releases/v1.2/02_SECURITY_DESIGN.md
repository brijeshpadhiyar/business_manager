# 02 — Local Application Security Design (Phase A)

**Scope:** Single-owner local app protection (PIN, optional Android biometrics, auto-lock, privacy shield, offline recovery, sensitive-action re-auth).  
**Strict Exclusion:** NO user accounts, NO cloud auth, NO roles/RBAC, NO Firebase Auth, NO internet dependency.

---

## 1. Architectural Principles

1. **App Lock Is a Single-Owner Privacy Gate — Not an Account System:** There is no username, no email, no "sign out", and no multi-user profile. The PIN simply unlocks the workshop app on this device.
2. **Zero Flash of Sensitive Data:** Locking is enforced at the root widget tree (`AppLockGate` wrapping `MaterialApp.router`'s `builder`), **above** all routes, dialogs, and bottom sheets — so neither the Dashboard nor any ledger screen can ever render before unlock.
3. **Strict Separation from SQLite & Backups:** All PIN hashes, salts, recovery hashes, and lockout counters live exclusively in **Android Keystore-backed `flutter_secure_storage`**, NEVER in SQLite tables, NEVER in `SharedPreferences`, and NEVER inside `.zip` backups.
4. **Honest Security Boundaries:** An application PIN protects against casual physical access and unauthorized use of the phone UI. It does **not** encrypt the SQLite database file on disk (SQLCipher is not enabled in V1.2). This limitation is explicitly stated in our threat model and in Settings -> Security.
5. **Opt-In Safe Upgrade Path:** Upgrading from V1.1 -> V1.2 keeps App Lock **disabled by default** until the owner deliberately enables it in `Settings -> App Lock & Security`. Existing workshop data remains immediately accessible after upgrade.

---

## 2. Cryptographic & Secure Storage Design (A1)

### 2.1 PIN Rules & Validation
- **Length:** **4-digit** (default, fast for daily workshop phone entry) or **6-digit** numeric PIN (`^[0-9]{4}$` or `^[0-9]{6}$`), chosen during setup.
- **Setup Flow:**
  1. Choose PIN length (4 digits recommended / 6 digits).
  2. Enter PIN on custom large-target StitchFlow numeric keypad (accessible >=56dp keys, masked dots, backspace, haptic feedback).
  3. Confirm PIN (must match exactly; clear localized error & reset confirmation step on mismatch).
  4. **Display One-Time Offline Recovery Key** (`XXXX-XXXX`, 8 characters from unambiguous Crockford-style alphabet `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` — excluding `0/O/1/I/L` to prevent misreading!). Require explicit checkbox confirmation (*"I have written down this Recovery Key in a safe place"*) before activating the lock.
  5. Optional prompt to enable **Fingerprint / Biometric Unlock** if device hardware has enrolled biometrics.
- **Change PIN Flow:** Requires verifying the **current PIN** (never biometric-only for changing PIN) -> enter new PIN -> confirm new PIN -> keep existing recovery key or offer 1-tap regeneration -> save atomically.
- **Disable PIN Flow:** Requires verifying the **current PIN** + confirmation dialog -> deletes PIN hash, salt, recovery hash, and resets lock state -> writes `audit_logs` record (`entity_type = 'app_security'`, `action_type = 'UPDATE'`, `reason = 'PIN disabled by owner'`).
- **Zero Plaintext Policy:**
  - Plain PIN strings are held only in ephemeral controller state during entry, cleared immediately (`_enteredPin = ''`) on submit/error/dispose.
  - Plain PINs, salts, hashes, and recovery keys are **NEVER** logged via `AppLogger` (even in `dev` builds!) and **NEVER** written to `audit_logs`.

### 2.2 PIN & Recovery Key Hashing (`PinHasher`)
We evaluate two modern KDF options for Dart `3.14.0` / Flutter `3.50.1`:

| Option | Algorithm | Pros | Cons | Verdict |
| :--- | :--- | :--- | :--- | :---: |
| **Option 1 (Recommended)** | **PBKDF2-HMAC-SHA256** (210,000 iterations, 16-byte `Random.secure()` salt, 32-byte key) via existing `crypto: ^3.0.6` in `Isolate.run` | Zero new dependencies, zero native FFI binaries, OWASP 2024+ recommended iteration floor for SHA-256 (210k+ / or tuned 150k–210k benchmarked ~150–250ms on mid-range Android), constant-time verification, 100% deterministic in tests | Less memory-hard than Argon2id against offline GPU attacks (mitigated by Keystore hardware wrapping + on-device rate limiting) | **RECOMMENDED** |
| **Option 2** | **Argon2id** via `cryptography: ^2.9.0` | Memory-hard (OWASP #1 for server passwords) | Pure-Dart Argon2id at 19 MiB takes 1.5–3.5s on budget Android phones (unacceptable daily unlock lag); adding `cryptography_flutter` adds native platform channel complexity for non-Argon2 ops | Documented Alternative |

**Stored Verifier Format (Self-Describing & Future-Upgradeable):**
```text
pbkdf2_hmac_sha256$v1$210000$<base64_16byte_salt>$<base64_32byte_dk>
```
- **Salt:** Unique 16 bytes generated via `Random.secure()` on every PIN creation, PIN change, and recovery key generation.
- **Execution:** Runs inside `Isolate.run(...)` so the 60fps unlock animation never drops frames.
- **Comparison:** Strict constant-time byte-array comparison (`diff |= a[i] ^ b[i]`) to prevent timing side-channels.
- **Same KDF for Recovery Key:** Normalized uppercase stripped of hyphens (`SF4K9M2P`), hashed with its own unique 16-byte `Random.secure()` salt and 210,000 iterations.

### 2.3 Secure Storage Evaluation (`flutter_secure_storage: ^10.3.4`)

| Option | Android Backing | Flutter 3.50 / Dart 3.14 Compatibility | Maintenance & Security Status |
| :--- | :--- | :---: | :--- |
| **`flutter_secure_storage: ^10.3.4`** | **Android Keystore** (`RSA/ECB/OAEPWithSHA-256AndMGF1Padding` key wrapping + `AES/GCM/NoPadding` storage cipher) | Compatible (`minSdk >= 23`; Flutter 3.50 defaults to `minSdk = 24`) | Actively maintained; **removed deprecated Jetpack `EncryptedSharedPreferences`** in v10.0.0. **RECOMMENDED.** |
| `shared_preferences` | Unencrypted XML in app private dir | Compatible | **REJECTED** for PIN/recovery hashes or lockout counters (plain XML readable on backup/rooted device). |
| SQLite table | `business_manager_*.sqlite` | Compatible | **REJECTED** because SQLite is exported in `.zip` backups & raw `.sqlite` exports. |

**Mandatory `flutter_secure_storage` v10 Configuration:**
```dart
const AndroidOptions(
  resetOnError: false, // CRITICAL: Never silently wipe PIN on transient KeyStore error!
  migrateOnAlgorithmChange: true,
)
```
- **Why `resetOnError: false`:** In v10, `resetOnError` defaults to `true`. If a transient KeyStore hiccup wiped storage silently, an app lock could silently turn OFF! Setting `resetOnError: false` surfaces a safe error state on the lock screen (prompting device restart or recovery) rather than silently bypassing security.
- **Manifest Requirement:** Set `android:allowBackup="false"` on `<application>` in `android/app/src/main/AndroidManifest.xml` so Android Auto Backup never copies encrypted prefs without the hardware Keystore key.
- **Flavor Key Isolation:** Every secure storage key is prefixed with `sf_${config.flavor.name}_`:
  - `sf_<flavor>_pin_enabled` (`'true'` / `'false'`)
  - `sf_<flavor>_pin_length` (`'4'` / `'6'`)
  - `sf_<flavor>_pin_verifier` (`pbkdf2_hmac_sha256$v1$...`)
  - `sf_<flavor>_recovery_verifier` (`pbkdf2_hmac_sha256$v1$...`)
  - `sf_<flavor>_biometric_enabled` (`'true'` / `'false'`)
  - `sf_<flavor>_lock_timeout_sec` (`'0'`, `'30'`, `'60'`, `'300'`, `'900'`)
  - `sf_<flavor>_flag_secure_enabled` (`'true'` / `'false'`)
  - `sf_<flavor>_failed_attempts` (`int`)
  - `sf_<flavor>_lockout_until_utc_ms` (`int`)
  - `sf_<flavor>_last_backgrounded_utc_ms` (`int`)

---

## 3. App Lock, Lifecycle & Privacy Shield Design (A2)

### 3.1 State Machine (`AppLockCubit` + `AppLockState`)

```
                    ┌───────────────────────────────────────────┐
                    │                COLD START                 │
                    │  Read secure storage BEFORE first frame   │
                    └─────────────────────┬─────────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼ (pinEnabled == false)                         ▼ (pinEnabled == true)
        ┌───────────────────┐                           ┌───────────────────┐
        │     DISABLED      │                           │      LOCKED       │
        │  (Normal App UI)  │                           │ (Lock Screen UI)  │
        └───────────────────┘                           └─────────┬─────────┘
                                                                  │
                                  Valid PIN or Biometric Success  │  Manual "Lock Now" /
                                  (clears failed_attempts)        │  Background > timeout /
                                                                  ▼  Process restart
                                                        ┌───────────────────┐
                                                        │     UNLOCKED      │
                                                        │ (Normal App UI)   │
                                                        └─────────┬─────────┘
                                                                  │
                                             AppLifecycleState.inactive / hidden / paused
                                                                  ▼
                                                        ┌───────────────────┐
                                                        │  PRIVACY_SHIELD   │
                                                        │ (Opaque Navy Veil)│
                                                        └───────────────────┘
```

### 3.2 Lifecycle Transitions & Process Death Safety
- **Bootstrap Check:** In `bootstrap.dart`, `await getIt<AppLockCubit>().initialize()` runs **before** `runApp()` completes its first business frame. If `pinEnabled == true`, the initial state is immediately `AppLockStatus.locked` — guaranteeing **zero flash** of Dashboard or sensitive screens on cold start or process restoration.
- **Entering Background (`inactive` / `hidden` / `paused`):**
  1. Immediately render `PrivacyShieldOverlay` (opaque Deep Navy `#172B4D` screen with StitchFlow Thread S logo) so Android's Recent Apps snapshot captures ONLY the branded shield, never workshop figures.
  2. On `paused` (unless a system prompt owned by StitchFlow is active, e.g., `local_auth` biometric dialog, `image_picker`, `file_picker`, or `share_plus` — tracked via a scoped `suspendAutoLockDuringSystemPicker()` guard with a hard 120-second safety cap!), persist `last_backgrounded_utc_ms` in secure storage.
  3. If timeout == `0` (Immediate), transition to `locked` immediately on `paused`.
- **Returning to Foreground (`resumed`):**
  1. Remove `PrivacyShieldOverlay` if unlocked and elapsed time `< lockTimeoutSeconds`.
  2. If `nowUtc - lastBackgroundedUtcMs >= lockTimeoutSeconds * 1000` (or if clock moved backwards by > 60s — anti-clock-tampering guard!), transition to `locked` and optionally auto-trigger Android biometric prompt if biometric unlock is enabled.
- **Inactivity Timer (While Foregrounded):**
  - Root `Listener(onPointerDown: ..., onPointerMove: ...)` resets a lightweight in-memory foreground inactivity timer (only when `pinEnabled && status == unlocked && timeout > 0`). If the phone sits open and idle on a workshop table past the configured timeout, the app locks automatically!
- **Manual "Lock Now":**
  - Available in `Settings -> App Lock & Security`, Dashboard Quick Actions (when PIN enabled), and App Bar icon button (when PIN enabled). Immediately sets state to `locked` and cancels foreground timer.
- **Dynamic `FLAG_SECURE` (`MainActivity.kt` MethodChannel `com.brijesh.stitchflow/window_security`):**
  - Always activates `WindowManager.LayoutParams.FLAG_SECURE` while on Lock Screen, PIN Setup/Change, or Recovery Key screens (preventing accidental screenshots of the Recovery Key or PIN entry!).
  - When unlocked, honors the user's `Protect Screen & Recents (Block Screenshots)` setting (default `ON` when PIN lock is enabled; user can toggle `OFF` if they want to screenshot a worker ledger).

### 3.3 Brute-Force Mitigation (Persistent Cooldown)
- Failed attempts and `lockout_until_utc_ms` are persisted in `flutter_secure_storage` (survives force-stop and device reboot):
  - Attempts 1–4: Immediate retry with remaining attempts indicator.
  - 5 consecutive failures -> **30-second** cooldown timer (countdown shown clearly in EN/GU).
  - 8 consecutive failures -> **2-minute** cooldown.
  - 10+ consecutive failures -> **5-minute** cooldown per subsequent failure.
- Biometric unlock is also paused during active PIN lockout cooldown (prevents bypassing lockout).
- Successful PIN unlock resets `failed_attempts = 0` and clears `lockout_until_utc_ms`.

---

## 4. Biometric Authentication Design (A3)

### 4.1 Package & Android Integration (`local_auth: ^3.0.2`)
- **Required Android Changes:**
  1. `android/app/src/main/kotlin/com/brijesh/stitchflow/MainActivity.kt`: Change `FlutterActivity` -> `FlutterFragmentActivity`.
  2. `android/app/src/main/AndroidManifest.xml`: Add `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`.
  3. Verify `android/app/src/main/res/values/styles.xml` compatibility with `FragmentActivity` + `BiometricPrompt` (Android API 24+; `LaunchTheme`/`NormalTheme` tested on Android 10–15).
- **v3.x API Usage (Flat Parameters & Typed Exceptions):**
  ```dart
  final didAuthenticate = await _localAuth.authenticate(
    localizedReason: reasonText, // Localized EN/GU
    biometricOnly: true,
    persistAcrossBackgrounding: true, // Replaces removed stickyAuth
  );
  ```
- **Hardware & Enrollment Check:**
  - `canCheckBiometrics && isDeviceSupported()` AND `(await getAvailableBiometrics()).isNotEmpty`.
  - If hardware is absent or no fingerprint/face is enrolled, the "Biometric Unlock" toggle in Settings displays a clear localized helper (*"No fingerprint or biometric is set up on this phone. Add one in Android Settings first."*) and stays disabled cleanly.
- **Error & Cancellation Handling (`LocalAuthException`):**
  - `userCanceled` / `systemCanceled` -> Remain **LOCKED**; dismiss error noise; keep PIN keypad active so the owner can type PIN immediately.
  - `notEnrolled` / `noCredentialsSet` / `noHardware` -> Remain **LOCKED**; automatically fall back to PIN and display non-blocking notice.
  - `temporaryLockout` / `biometricLockout` -> Remain **LOCKED**; inform user biometric sensor is temporarily locked by Android; PIN remains immediately usable.
  - Any unexpected error -> Fail **CLOSED** (remain `LOCKED`), never bypass!

---

## 5. Recovery, Sensitive Operations & Backup Safety (A4)

### 5.1 Safe Offline PIN Recovery Strategy
| Scenario | Recovery Mechanism | Data Preserved? | Security Trade-Off |
| :--- | :--- | :---: | :--- |
| **Forgot PIN, has written Recovery Key** | Tap *"Forgot PIN?"* on Lock Screen -> Enter 8-char Recovery Key (`XXXX-XXXX`, subject to the same rate-limiting backoff!) -> Verifies salted PBKDF2 hash -> Prompts to set a new PIN -> Generates & displays a fresh Recovery Key -> Logs `APP_SECURITY` audit entry. | **100% Preserved** | High security + practical workshop safety: no silent bypass, requires physical possession of the owner's written Recovery Key. |
| **Forgot PIN AND lost Recovery Key** | App displays clear bilingual explanation: *"For your business privacy, StitchFlow cannot reset your PIN without your Recovery Key. If you have a saved StitchFlow `.zip` backup, you can reinstall/clear app data and restore your backup."* | **Preserved via prior `.zip` backup** (lost only if user never backed up AND lost both PIN and Recovery Key) | Deliberate trade-off: adding an unauthenticated "Reset PIN" button would completely defeat local PIN security. Combined with V1.2's weekly Backup Reminder (Phase D), data loss risk is minimized cleanly. |

### 5.2 Sensitive Action Re-Authentication
When App Lock is enabled, the following sensitive operations require a fresh **PIN / Biometric verification sheet** (`SecurityReauthSheet`):
1. **Restore from `.zip` Backup** (destructive replacement of live database).
2. **Export Raw `.sqlite` File** (exports full unencrypted business database).
3. **Change PIN / Disable App Lock / View-Regenerate Recovery Key** (PIN-only verification — biometrics alone cannot disable PIN!).

### 5.3 Interaction with Backup & Restore
- `.zip` backups contain `database.sqlite`, `media/*`, and `manifest.json` — **zero security credentials**.
- Restoring a backup calls `AppSessionController.instance.reloadSession(_config)`. Because `AppLockCubit` re-reads secure storage on DI reload, we pass a short-lived in-memory `preserveUnlockedSession` token inside `AppSessionController` during an already-authenticated restore so the owner sees the restore confirmation cleanly without being locked out mid-flow.

---

## 6. Threat Model

| Threat Vector | Mitigation in StitchFlow V1.2 | Residual Risk / Honest Limitation |
| :--- | :--- | :--- |
| **1. Unauthorized casual physical access** (someone picks up father's unlocked phone at workshop/home) | Local 4–6 digit PIN + biometric unlock + auto-lock on background & foreground inactivity + Lock Now button. | Low residual risk once PIN is enabled and timeout is <= 1–5 min. |
| **2. App switcher / background snapshots** | Instant opaque StitchFlow `PrivacyShieldOverlay` on `inactive`/`hidden` + dynamic Android `FLAG_SECURE`. | Mitigated on Android; if owner turns off global `FLAG_SECURE` to take ledger screenshots, `PrivacyShieldOverlay` still covers Recents on backgrounding. |
| **3. PIN brute-force attempts** | Persistent exponential lockout in `flutter_secure_storage` (survives kill/reboot) + 210k-iteration PBKDF2-HMAC-SHA256 (`~150–250ms` per guess). | Effective against interactive guessing (a 4-digit PIN would take months under 5-min lockouts). Offline brute force against a 4-digit PIN is feasible only if an attacker gains root access AND extracts hardware Keystore keys. |
| **4. Local SQLite data exposure** | Database stays in Android private internal app directory (`getApplicationDocumentsDirectory`), `android:allowBackup="false"`, raw export gated by re-auth. | **SQLite file is NOT encrypted at rest in V1.2.** Anyone with root/ADB backup bypass or access to an exported `.zip` backup can read the SQLite file. Clearly disclosed in UI & docs; SQLCipher remains a future V2 option if ever required. |
| **5. Device compromise / rooted phone / OS lock disabled** | Android Keystore wraps secure-storage keys; no plaintext PIN logged or stored. | If the Android device itself is rooted or running malware with root privileges, local app-level PIN security cannot protect on-device data. Owners should also keep Android's OS screen lock enabled. |

---

## 7. Module Structure (`lib/features/security/`)

```text
lib/features/security/
├── domain/
│   ├── entities/security_entities.dart        # LockTimeoutOption, AppLockStatus, SecuritySettings, BiometricAvailability
│   ├── repositories/security_repository.dart  # Abstract interface (100% mockable in tests)
│   └── services/pin_hasher.dart               # Pure Dart PBKDF2-HMAC-SHA256 + RecoveryKeyGenerator + constant-time verify
├── data/
│   ├── repositories/secure_storage_security_repository.dart
│   ├── services/local_auth_biometric_service.dart
│   └── services/window_security_channel.dart  # MethodChannel for Android FLAG_SECURE
└── presentation/
    ├── bloc/app_lock_cubit.dart               # @lazySingleton root lock state machine + lifecycle hooks
    ├── pages/
    │   ├── app_lock_screen.dart               # Branded StitchFlow PIN + Biometric + Lockout + Forgot PIN screen
    │   ├── security_settings_page.dart        # /settings/security hub
    │   ├── pin_setup_page.dart                # Create / Change PIN + Recovery Key confirmation flow
    │   └── pin_recovery_page.dart             # Offline Recovery Key verification -> Set New PIN
    └── widgets/
        ├── app_lock_gate.dart                 # Root overlay + PrivacyShieldOverlay + foreground inactivity Listener
        ├── pin_keypad.dart                    # Accessible 360dp-safe numeric keypad + masked dots
        └── security_reauth_dialog.dart        # Reusable modal PIN/Biometric gate for backup/restore/settings
```
