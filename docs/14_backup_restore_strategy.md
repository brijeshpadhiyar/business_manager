# 14 — Backup & Restore Strategy

## 1. Confirmed Version 1 Backup & Security Model

- **Private Internal Database:** The live `.sqlite` database stays inside private application storage (never exposed in public folders).
- **Explicit User Action Only:** Exports and backups happen strictly when the user taps **Export SQLite Database** or **Create Full Backup**.
- **Unencrypted in V1:** Both the exported raw `.sqlite` file and the full `.zip` backup archive are **unencrypted in V1** so the owner can easily open the database in external SQLite viewer tools (e.g., DB Browser for SQLite, SQLite Viewer on Android/PC) and move backups across devices without key-loss risk.
- **Future Enhancements (Post-V1):**
  - Optional password-based `.zip` encryption (AES-256).
  - Optional app-level PIN / biometric lock (`local_auth` + `flutter_secure_storage`) as a separate security feature.

---

## 2. Export Option A — Raw SQLite Database Export (`.sqlite`)

Purpose: Allow inspecting all tables, ledgers, and audit trails in any external SQLite viewer tool.

### Export Procedure (WAL-Safe Snapshot — Never Copy Raw Live File)
Because the database runs in `WAL` mode, directly copying the main `.sqlite` file risks omitting uncheckpointed frames in `-wal`. Always create a consistent snapshot:
1. Flush pending WAL frames safely:
   ```sql
   PRAGMA wal_checkpoint(TRUNCATE);
   ```
2. **Native Platforms (Android, iOS, Windows, macOS, Linux):** Execute `VACUUM INTO '<temp_exports>/business_manager_<flavor>_<YYYYMMDD_HHMMSS_IST>.sqlite'` to produce an atomic, compacted, self-contained single `.sqlite` file (zero `-wal`/`-shm` dependency) without closing the active DB connection. Verify immediately with `PRAGMA integrity_check;`.
3. **Web Platform (`sqlite3.wasm`):** Flush/checkpoint inside the Drift Web Worker and serialize/read consistent SQLite bytes from OPFS / `sqlite3_serialize` for browser download (note: large media `.zip` archives on Web are bounded by browser RAM).
4. Present the OS share / save-to-location dialog (`share_plus` / `file_picker.saveFile`).
5. Write a `BACKUP_EXPORT` entry into `audit_logs` and delete temporary export files after completion.

---

## 3. Export Option B — Complete Full Backup Bundle (`.zip`)

Purpose: Full disaster recovery and device-to-device migration (e.g., switching to a new Android phone).

### Archive Structure
```text
business_manager_backup_<flavor>_<YYYYMMDD_HHMMSS_IST>.zip
├── manifest.json
├── database.sqlite                  # Clean VACUUM INTO snapshot
└── media/
    ├── lots/<lot_id>/<id>.jpg
    ├── movements/<id>/<id>.jpg
    ├── payments/<id>/<id>.jpg
    └── profile/<id>.png
```

### `manifest.json` Schema
```json
{
  "format_version": 1,
  "app_version": "1.0.0+1",
  "flavor": "prod",
  "schema_version": 1,
  "created_at_utc": "2026-11-23T05:30:00.000Z",
  "created_at_ist": "2026-11-23 11:00:00 IST",
  "database_sha256": "<hex>",
  "database_size_bytes": 245760,
  "attachments_count": 14,
  "attachments": [
    {
      "relative_path": "media/lots/019a.../019b....jpg",
      "sha256": "<hex>",
      "size_bytes": 182400
    }
  ]
}
```

---

## 4. Atomic Full Restore Procedure (Fail-Safe)

Restoring a backup must **never** leave the app with a half-restored or corrupted database:

1. **Pick & Extract to Staging:** User selects a `.zip` file via `file_picker`; extract into `<temp_restore_staging>/`.
2. **Pre-Flight Validation (`BackupValidator`):**
   - Verify `manifest.json` exists and `format_version` is supported.
   - Verify `schema_version <= currentAppSchemaVersion` (if backup is from a newer app version, reject with clear localized message asking to update the app).
   - Verify `database.sqlite` SHA-256 matches `manifest.database_sha256`.
   - Verify every listed attachment exists and matches its SHA-256 checksum.
   - Run `PRAGMA integrity_check;` on staged `database.sqlite` in read-only mode.
   - **Production Overwrite & Cross-Flavor Protection:** Restoring into `prod` requires an explicit two-step confirmation dialog displaying backup date (`Asia/Kolkata`), flavor, and summary counts before overwriting live data. Restoring a `dev` backup into `prod` is **blocked** in `prod` to prevent test data from polluting production.
3. **Automatic Pre-Restore Safety Snapshot:**
   - Copy current live DB + media to `<temp_rollback_snapshot>/`.
4. **Atomic Swap:**
   - Close active `AppDatabase` connection cleanly.
   - Replace live `.sqlite` (removing stale `-wal` and `-shm` files) and swap `media_<flavor>/` directory.
   - Reopen `AppDatabase` (automatically runs Drift migrations if `manifest.schema_version < currentAppSchemaVersion`).
   - Record `BACKUP_RESTORE` audit log and refresh DI/BLoC state.
5. **Automatic Rollback on Failure:**
   - If any step in Step 4 throws, immediately restore `<temp_rollback_snapshot>/`, reopen the original DB, and report a localized error.

---

## 5. Platform Backup Capability Matrix

| Capability | Android | iOS | Windows / macOS / Linux | Web |
| :--- | :---: | :---: | :---: | :---: |
| Raw `.sqlite` Export | Yes (`VACUUM INTO` + Share/Save) | Yes (`VACUUM INTO` + Share/Files) | Yes (`VACUUM INTO` + Save dialog) | Yes (WASM byte export / OPFS read → Browser download) |
| Full `.zip` Backup | Yes | Yes | Yes | Yes (Browser download) |
| Full `.zip` Restore | Yes (`file_picker`) | Yes (`file_picker`) | Yes (`file_picker`) | Yes (Browser upload + OPFS/IDB swap) |
