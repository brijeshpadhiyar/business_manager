# 13 — Offline Storage Strategy

## 1. Storage Architecture Principles

- **100% Local & Private:** Both the SQLite database and all local media (lot photos, receipts, attachments) live strictly inside **OS-enforced private application storage**.
- **Never Public Storage:** The app never places its live `.sqlite` file in Android shared/public external storage (`/storage/emulated/0/Documents` or `Downloads`). Files leave private storage **only** when the user explicitly triggers an Export or Backup.
- **Flavor Isolation:** `dev` and `prod` use distinct filenames and media subdirectories (`business_manager_dev.sqlite` + `media_dev/` vs. `business_manager_prod.sqlite` + `media_prod/`).

---

## 2. Platform-Specific Storage Map

| Platform | SQLite Engine | Database Location | Media / Attachments Root | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Android (Primary)** | `sqlite3 ^3.9.1` (build hooks) + `drift_flutter` | App private files dir (`getApplicationDocumentsDirectory()/db/`) | `<appDocsDir>/media_<flavor>/` | Private sandbox; inaccessible to other apps without root |
| **iOS** | `sqlite3 ^3.9.1` + `drift_flutter` | App Sandbox `Documents/db/` | `<appDocsDir>/media_<flavor>/` | Excluded from unsolicited cloud sync unless desired |
| **Windows** | `sqlite3 ^3.9.1` + `drift_flutter` | `%APPDATA%\...\business_manager\<flavor>\db\` | `...\<flavor>\media\` | Full native filesystem support |
| **macOS** | `sqlite3 ^3.9.1` + `drift_flutter` | App Support / Sandbox Container `db/` | `...\<flavor>\media\` | Sandboxed container |
| **Linux** | `sqlite3 ^3.9.1` + `drift_flutter` | `$XDG_DATA_HOME/business_manager/<flavor>/db/` | `...\<flavor>\media\` | Standard XDG data dir |
| **Web** | `sqlite3.wasm` + `drift_worker.js` | Browser **OPFS** (preferred) → **IndexedDB** fallback | Browser OPFS / IndexedDB blob store | See Web persistence caveats below |

---

## 3. Local Media & Attachment Directory Layout

All `attachments.relative_path` entries are stored **relative** to the flavor media root so backups are 100% OS-independent:

```text
<appDocsDir>/
├── db/
│   └── business_manager_<flavor>.sqlite       # + -wal and -shm sidecar files
├── media_<flavor>/
│   ├── lots/<lot_id>/<attachment_id>.jpg
│   ├── movements/<movement_id>/<attachment_id>.jpg
│   ├── payments/<payment_id>/<attachment_id>.jpg
│   └── profile/<attachment_id>.png
└── temp_exports/                              # Cleaned up automatically after share/export
```

- **Image Compression:** Camera/gallery photos on Android, iOS, and Web are resized/compressed natively via `image_picker` (`maxWidth: 1600`, `maxHeight: 1600`, `imageQuality: 80`) with zero extra native plugins; desktop file-picker imports store validated files up to a configurable size guard, and every saved file's SHA-256 hash and byte size are recorded in `attachments`.
- **Orphan Safety:** Deleting an attachment soft-deletes its `attachments` row first; physical file cleanup runs only for confirmed soft-deleted items during explicit storage maintenance so backups/audits remain intact.

---

## 4. SQLite Configuration & Migrations

- **PRAGMAs applied in `MigrationStrategy.beforeOpen`:**
  - `PRAGMA foreign_keys = ON;`
  - `PRAGMA journal_mode = WAL;`
  - `PRAGMA synchronous = FULL;` *(strict ACID durability — see `ADR-012` & `docs/24_FINAL_TECHNICAL_SAFEGUARDS.md`)*
  - `PRAGMA busy_timeout = 5000;`
- **Background Isolate:** Native platforms use `NativeDatabase.createInBackground` (via `drift_flutter`) so heavy queries and backup checkpoints never block UI frames.
- **Schema Versioning:** `AppDatabase.schemaVersion` increments on every schema change; Drift `stepByStep` migrations are generated and verified with automated upgrade tests.

---

## 5. Web SQLite WASM Persistence & Limitations

- Drift Web (`WasmDatabase.open`) requires `web/sqlite3.wasm` and `web/drift_worker.js` matching the installed `sqlite3` / `drift` versions.
- **Storage Tier Negotiation:**
  1. **OPFS (via `SharedArrayBuffer`):** Requires HTTP headers `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.
  2. **IndexedDB via Web Worker:** Automatic fallback if COOP/COEP headers are unavailable.
  3. **In-Memory:** Only in restricted private/incognito sessions; UI must show a persistent warning banner.
- **Browser Eviction Caveat:** Browsers may evict site storage under disk pressure unless `navigator.storage.persist()` is granted. Web users should be reminded to export `.zip` backups regularly.
