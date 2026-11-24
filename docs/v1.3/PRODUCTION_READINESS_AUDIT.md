# StitchFlow V1.3 – Production Readiness Audit (Phase 1)

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`  
**Audit Mode:** Strictly Read-Only Baseline Inspection  
**Verified Baseline:** `flutter analyze` = 0 issues | `flutter test` = 160/160 passed | Schema v6 (19 tables) | Universal Release APK = `76.42 MB`

---

## 1. Executive Summary

StitchFlow V1.3 has a strong offline-first architecture (BLoC/Cubit + Drift/SQLite + GoRouter + GetIt/Injectable + Glassmorphism + EN/GU localization + `AppMessageService` + centralized `AppValidators`). However, the read-only audit identified **1 release-blocking P0 configuration issue** (release APK signed with debug keystore) and **several high-value P1/P2 performance, database, and error-hygiene items** that should be addressed before external production rollout.

---

## 2. Findings Register (Severity, Evidence & Release Impact)

| ID | Severity | Release Blocker? | Affected Module / File | Evidence | Recommended Fix |
|---|---|---|---|---|---|
| **PR-01** | **P0 – Critical** | **YES** (for Play Store / external distribution) | `android/app/build.gradle.kts:48` | `buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }` | Add `key.properties`-backed release signing configuration with safe fallback for local CI builds (never commit keystores/passwords). |
| **PR-02** | **P1 – High** | No | `pubspec.yaml:5` & `lib/core/config/app_identity.dart` | `version: 1.2.0+3` does not match StitchFlow V1.3 release (`1.3.0+4`). | Bump `pubspec.yaml` and `AppIdentity` version consistently to `1.3.0+4`. |
| **PR-03** | **P1 – High** | No | `lib/features/lots/presentation/pages/lot_detail_page.dart:805,1262` | `FutureBuilder` inside `build()` recreates `getJobRoutingOverview(lotId)` and `readPhotoBytes(...)` futures on every widget rebuild (e.g., every keystroke in Design Search). | Cache futures in `State` / `LotDetailCubit` so search typing or minor UI rebuilds never re-run multi-table SQLite queries or re-read image files from disk. |
| **PR-04** | **P1 – High** | No | `lib/features/lots/data/repositories/lot_repository_impl.dart:62-72` | Classic **N+1 SQLite query** in `getLotDetail`: loops over `designRows` calling `getColoursForDesign(d.id)` sequentially. | Add batch `getColoursForDesigns(List<String> designIds)` (`WHERE lot_design_id IN (...) AND deleted_at IS NULL`) to `LotDao` and group in memory. |
| **PR-05** | **P1 – High** | No | `lib/core/database/migrations/schema_indexes.dart` & `stock_movement_dao.dart` | `getMovementsForLot(lotId)` (`WHERE lot_id = ? ORDER BY transaction_at`) and `hasMovementsUsingRate(rateId)` (`WHERE source_rate_id = ?`) have **no supporting index**, causing full table scans of `stock_movements`. | Add additive indexes via Schema v7 (`idx_sm_lot_tx`, `idx_sm_source_rate`, `idx_lots_active_tx`) with full v1–v6 -> v7 migration tests. |
| **PR-06** | **P1 – High** | No | Multiple Cubits (`accounting_overview_cubit.dart:83`, `worker_ledger_cubit.dart:110`, `dashboard_cubit.dart:47`, `lot_detail_cubit.dart:48`, `lot_list_cubit.dart:54`, `inventory_overview_cubit.dart:53`, `business_profile_cubit.dart:27`, `backup_restore_cubit.dart:98`) | 20+ catch blocks store raw `e.toString()` in `errorMessage`, risking leaking raw SQLite/Drift exception strings into `AppErrorView`. | Map `DomainValidationException` through `ValidationLocalizer` and sanitize unexpected exceptions to a clean user-facing error code/message while logging full details to `AppLogger`. |
| **PR-07** | **P2 – Medium** | No | `lot_list_page.dart`, `worker_list_page.dart`, `process_list_page.dart` | Still use raw `AppTextField` for search without debounce, triggering full SQLite reads on every single keystroke. | Enhance `AppSearchField` with optional `debounceDuration` (e.g. 220ms) and migrate `lot_list_page.dart`, `worker_list_page.dart`, and `process_list_page.dart` to `AppSearchField`. |
| **PR-08** | **P2 – Medium** | No | `lib/core/database/daos/job_process_dao.dart:57-65` | `getNextSequenceOrderForLot(lotId)` loads all `job_processes` rows into memory to find `max(sequenceOrder)`. | Replace with `SELECT COALESCE(MAX(sequence_order), 0) + 1` SQL aggregate query. |
| **PR-09** | **P2 – Medium** | No | `build/app/outputs/flutter-apk/app-prod-release.apk` (`76.42 MB`) | Single universal fat APK bundles all 3 ABIs (`armeabi-v7a`, `arm64-v8a`, `x86_64`) without R8 shrinking flags enabled. | Document `--split-per-abi` / Play Store `.aab` release build path and evaluate enabling safe R8 resource/code shrinking in `build.gradle.kts`. |

---

## 3. Security & Reliability Audit Notes

- **PIN & Biometrics**: PBKDF2-HMAC-SHA256 salted hash stored in `flutter_secure_storage`, offline 8-character Crockford Recovery Key, contextual `SecurityReauthDialog` (frosted `AppDialog`) before destructive backup restore / raw SQLite export / PIN changes.
- **Android Manifest**: `android:allowBackup="false"` is properly set; permissions are minimal and justified (`USE_BIOMETRIC`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`).
- **Backup & Restore**: `NativeBackupRestoreService` uses `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM INTO` + read-only `PRAGMA integrity_check` + SHA-256 verification before atomic swap.
- **Zero `print()` / `debugPrint()`** calls found anywhere in `lib/`.
- **Zero raw `AlertDialog` or direct `ScaffoldMessenger.showSnackBar`** bypasses remain in feature code.
- **Disclaimer**: This is a source-code and automated-test readiness review; StitchFlow has not undergone third-party penetration testing or formal security certification.
