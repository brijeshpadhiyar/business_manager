# 04 — Technology Stack & Verified Compatibility

All SDK and package versions below were verified against official Flutter, Dart, Drift, and `pub.dev` documentation on **2026-11-23** against the workspace's installed toolchain.

---

## 1. Core SDK & Toolchain

| Component | Verified Version | Official Source | Notes |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | `3.50.1` (channel `stable`) | https://docs.flutter.dev/release/release-notes | Verified locally via `flutter --version` |
| **Dart SDK** | `3.14.0` (`sdk: ^3.14.0`) | https://dart.dev/get-dart/archive | Bundled with Flutter 3.50.1 |
| **Android JDK** | Java 17 (Gradle Kotlin DSL) | https://docs.flutter.dev/deployment/android | Configured in `android/app/build.gradle.kts` |
| **UI Foundation** | `material_ui: ^1.11.1` (`flutter.dev`, Material 3) | https://pub.dev/packages/material_ui | Official decoupled Flutter Material 3 library (Flutter 3.47+); verified `1.11.1` in `pubspec.lock` |

---

## 2. Production Dependencies (Verified Compatibility Matrix)

| Package | Version | Purpose | Android | iOS | Web | Win | macOS | Linux | Official Source |
| :--- | :--- | :--- | :-: | :-: | :-: | :-: | :-: | :-: | :--- |
| `material_ui` | `^1.11.1` | Official decoupled Flutter Material 3 UI library (`flutter.dev`) | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/material_ui |
| `flutter_bloc` | `^9.1.1` | Predictable BLoC/Cubit state management | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/flutter_bloc |
| `drift` | `^2.35.3` | Type-safe reactive SQLite ORM, migrations, DAOs | Yes | Yes | Yes | Yes | Yes | Yes | https://drift.simonbinder.eu |
| `drift_flutter` | `^0.3.1` | Cross-platform Drift connection helper (native + web) | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/drift_flutter |
| `sqlite3` | `^3.9.1` | SQLite bindings + **automatic native build hooks** | Yes | Yes | Yes* | Yes | Yes | Yes | https://pub.dev/packages/sqlite3 |
| `go_router` | `^18.1.4` | Declarative Navigation 2.0 routing & deep links | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/go_router |
| `freezed_annotation` | `^3.1.0` | Immutable entities, union states, `copyWith` | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/freezed_annotation |
| `json_annotation` | `^4.12.0` | JSON serialization for audit diffs & backup manifest | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/json_annotation |
| `get_it` | `^8.0.2` | Service locator for Dependency Injection | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/get_it |
| `injectable` | `^3.0.0` | Annotation-based DI registration for `get_it` | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/injectable |
| `flutter_localizations` | `sdk: flutter` | Official Material/Cupertino/Widgets localization | Yes | Yes | Yes | Yes | Yes | Yes | https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization |
| `intl` | `^0.20.3` | ARB formatting, Indian currency (`₹`), IST dates | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/intl |
| `shared_preferences` | `^2.5.3` | Persist theme mode, locale, UI preferences | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/shared_preferences |
| `path_provider` | `^2.1.6` | OS private app directories (native platforms) | Yes | Yes | No** | Yes | Yes | Yes | https://pub.dev/packages/path_provider |
| `path` | `^1.9.1` | Cross-platform path joining | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/path |
| `image_picker` | `^1.2.4` | Camera & gallery photo capture + native resize/JPEG compression (`maxWidth`/`imageQuality`) | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/image_picker |
| `file_picker` | `^13.4.1` | Pick `.zip` backups, attachments, save dialogs | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/file_picker |
| `archive` | `^4.6.0` | Pure Dart `.zip` creation & extraction (backups) | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/archive |
| `share_plus` | `^13.3.1` | Explicit user export/share of `.sqlite` & `.zip` | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/share_plus |
| `timezone` | `^0.11.2` | IANA `Asia/Kolkata` timezone conversions | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/timezone |
| `uuid` | `^4.6.0` | Offline-safe UUIDv7/v4 primary keys | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/uuid |
| `crypto` | `^3.0.6` | SHA-256 checksums for backup `manifest.json` | Yes | Yes | Yes | Yes | Yes | Yes | https://pub.dev/packages/crypto |

*\*Web SQLite requires `sqlite3.wasm` and `drift_worker.js` static assets in `web/`.*
*\*\*`path_provider` is guarded behind a `PlatformStorageService` abstraction; Web uses browser download/upload + OPFS/IndexedDB rather than filesystem paths.*

---

## 3. Dev & Testing Dependencies

| Package | Version | Purpose | Official Source |
| :--- | :--- | :--- | :--- |
| `build_runner` | `^2.16.1` | Code generation runner *(pinned to `2.16.1` for `injectable_generator 3.1.3` / `lean_builder` compatibility)* | https://pub.dev/packages/build_runner |
| `drift_dev` | `^2.35.3` | Drift table/DAO/migration generator | https://pub.dev/packages/drift_dev |
| `freezed` | `^4.0.2` | Immutable data classes & sealed unions | https://pub.dev/packages/freezed |
| `json_serializable` | `^6.15.2` | JSON `fromJson`/`toJson` generator | https://pub.dev/packages/json_serializable |
| `injectable_generator` | `^3.1.3` | DI graph generator for `get_it` | https://pub.dev/packages/injectable_generator |
| `bloc_test` | `^10.0.0` | Unit testing for BLoCs & Cubits | https://pub.dev/packages/bloc_test |
| `mocktail` | `^1.0.5` | Null-safe mocking without codegen | https://pub.dev/packages/mocktail |
| `flutter_lints` | `^6.0.0` | Official Flutter lint ruleset | https://pub.dev/packages/flutter_lints |

---

## 4. Important Package Decisions & Deprecation Notes

1. **No `sqlite3_flutter_libs`:** Starting with `sqlite3 ^3.x`, native SQLite binaries are bundled automatically via Dart/Flutter build hooks. `sqlite3_flutter_libs` is deprecated and must **not** be added.
2. **Keep & Upgrade `material_ui: ^1.11.1` (Official Flutter Material 3 Package):**
   - **Verified Publisher & Maintenance:** Published and actively maintained by the official Flutter team (`flutter.dev`) on `pub.dev`; resolved to `1.11.1` in `pubspec.lock` (requires `flutter: >=3.47.0`, `dart: >=3.14.0`).
   - **Why It Exists:** Starting in Flutter `3.47+`, Google decoupled the Material Design library from the core Flutter SDK (`package:flutter/material.dart`) into `package:material_ui/material_ui.dart` so Material 3 components, theming, typography, and motion can evolve independently of the core engine.
   - **Platform Support:** Full support across all 6 target platforms (Android, iOS, Web, Windows, macOS, Linux).
   - **Integration Rule:** Pin `material_ui: ^1.11.1` in `pubspec.yaml`, import `package:material_ui/material_ui.dart` (consistent with `dart fix --apply --code=migrate_design_widgets`), and wrap its Material 3 primitives cleanly inside our centralized `lib/core/widgets/` components without duplicating Material widgets or adding third-party UI kits.
3. **Web SQLite WASM Persistence Strategy & Limitations:**
   - Drift Web (`package:drift/wasm.dart` via `drift_flutter`) automatically negotiates the best available browser storage:
     1. **OPFS (Origin Private File System)** via `SharedArrayBuffer` (fastest, true file persistence) — requires hosting headers `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.
     2. **IndexedDB via Web Worker** (automatic graceful fallback when COOP/COEP headers are absent; slightly slower and subject to browser storage quota / eviction policies).
     3. **In-Memory** (last resort in restricted private/incognito browsing — UI must warn the user).
   - **Web Media Limitation:** Browsers do not expose arbitrary local directories; on Web, attachments/photos must be stored as binary blobs in IndexedDB/OPFS or exported via browser download rather than `dart:io` `File` paths.
4. **No Backend / Cloud SDKs:** Zero `dio`, `http`, `firebase_*`, or `supabase_*` dependencies in V1.
