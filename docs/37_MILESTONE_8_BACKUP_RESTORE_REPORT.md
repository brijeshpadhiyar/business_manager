# 37 — Milestone 8 Implementation Report (Backup, Restore & Data Safety)

**Completed Date:** 2026-11-23  
**SDK & Stack Verified:** Flutter `3.50.1` (`stable`) / Dart `3.14.0` / `archive: ^4.6.0` / `file_picker: ^13.4.1` / `share_plus: ^13.3.1`  
**Status:** Complete

---

## 1. Features Implemented

- **WAL-Consistent SQLite Snapshotting:**
  - Always flushes pending WAL frames via `PRAGMA wal_checkpoint(TRUNCATE);` and produces a compacted, self-contained SQLite file via `VACUUM INTO '<staging_path>'`—never blindly copying live `.sqlite` files while WAL writes are pending.
  - Verifies every snapshot read-only via `PRAGMA integrity_check;`.
- **Full Offline `.zip` Backup Bundle:**
  - Packages `manifest.json` (format version, app version, flavor, schema version, UTC & IST timestamps, database SHA-256 & byte size, attachment list with per-file SHA-256 checksums, and summary record counts), `database.sqlite`, and all private lot/media photos under `media/`.
  - Logs `BACKUP_EXPORT` into `audit_logs` and supports OS Share/Save via `share_plus`.
- **Pre-Flight Restore Validation & Atomic Fail-Safe Restore:**
  - Inspects and validates `.zip` archives in an isolated temp staging directory before modifying any live data:
    - Zip-Slip path traversal protection.
    - Manifest format & schema compatibility check (`backup.schemaVersion <= currentSchemaVersion`).
    - Cross-flavor safety guard: blocks restoring a `dev` backup into Production StitchFlow (`cross_flavor_blocked`).
    - Database SHA-256 verification + read-only `PRAGMA integrity_check;`.
    - Attachment existence & SHA-256 checksum verification for every file.
  - Explicit destructive confirmation dialog displaying backup IST date, flavor, schema version, and record/photo counts.
  - Automatic pre-restore safety snapshot of current live DB + media, clean DB close, stale `-wal`/`-shm` cleanup, atomic DB + media swap, fresh reopen & `integrity_check` (applying Drift migrations automatically if older schema), `BACKUP_RESTORE` audit log, and automatic rollback to pre-restore snapshot on any failure.
  - Clean `AppSessionController.reloadSession(...)` re-initializes the entire DI graph & widget tree immediately after restore so zero stale closed DB handles exist.
- **Raw `.sqlite` Inspection Export (Clearly Separated):**
  - Separate action creating a standalone `VACUUM INTO` `.sqlite` file for inspection in external SQLite viewer tools (clearly documented as database-only, excluding photos).

---

## 2. Architecture & Important Files

- `lib/core/di/app_session_controller.dart` (clean DI & UI session rebind after restore)
- `lib/features/backup/domain/entities/backup_entities.dart`
- `lib/features/backup/domain/services/backup_restore_service.dart`
- `lib/features/backup/data/services/native_backup_restore_service.dart`
- `lib/features/backup/presentation/bloc/backup_restore_cubit.dart`
- `lib/features/backup/presentation/pages/backup_restore_page.dart`

---

## 3. Database Changes

- None (`schemaVersion = 2` preserved). Uses existing `BACKUP_EXPORT` and `BACKUP_RESTORE` `audit_logs` action types.

---

## 4. Packages Added / Removed

- Zero new packages added (reused already-installed `archive: ^4.6.0`, `file_picker: ^13.4.1`, `share_plus: ^13.3.1`, `crypto: ^3.0.6`, `sqlite3: ^3.9.1`).

---

## 5. Verification & Tests

- Full end-to-end backup, raw `.sqlite` export, cross-flavor block (`dev → prod`), tampered-ZIP SHA-256 rejection, media deletion + full restore verification (lots, stock, ledger, photo bytes, and `BACKUP_RESTORE` audit log): `test/features/end_to_end_business_workflow_test.dart`
- UI smoke & EN/GU Dark-mode test: `test/widget/milestones_6_to_9_ui_test.dart`

---

## 6. Known Issues & Limitations

- V1 backups are unencrypted by design (`docs/14_backup_restore_strategy.md`) so the workshop owner can inspect `.sqlite` files directly and migrate between phones without key-loss risk. Keep backup `.zip` files in a trusted location.
- Web browser backup/restore is out of scope for the native Android-first `NativeBackupRestoreService` implementation (Android, Windows, macOS, Linux, and iOS native storage paths are fully supported).

---

## 7. Manual Android Testing Instructions

1. Create a lot with a photo, issue stock, and record a payment.
2. Open **Dashboard → Backup & Restore** (or **Business Profile → Backup, Restore & Data Safety**).
3. Tap **Create Full Backup (.zip)**, wait for progress to finish, and tap **Share / Save File** to save it to Downloads or Google Drive/USB.
4. Create a temporary dummy lot to verify data changes.
5. Tap **Restore from Backup (.zip)**, pick the saved `.zip`, verify the **Backup Archive Verified** summary card, tap **Yes, Restore Now**, confirm the dialog, and verify the dummy lot is gone while all original data and lot photos are 100% restored.
