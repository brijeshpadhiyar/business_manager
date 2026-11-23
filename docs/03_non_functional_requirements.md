# 03 — Non-Functional Requirements

## 1. Offline-First Reliability & Data Integrity

- **NFR-001 (100% Offline Capability):** Every screen, workflow, calculation, report, photo capture, and backup/restore operation must work with airplane mode enabled.
- **NFR-002 (ACID Atomicity):** All multi-table writes (e.g., stock return + labour entry + audit log) must execute inside SQLite transactions with `PRAGMA foreign_keys = ON`.
- **NFR-003 (Zero Financial Drift):** Monetary values must be stored and calculated using 64-bit integers (`int` paise). Floating-point arithmetic is prohibited for currency sums, rates, and balances.
- **NFR-004 (Crash-Safe ACID Durability):** SQLite runs in `WAL` (Write-Ahead Logging) mode with **`PRAGMA synchronous = FULL;`** (`ADR-012`), ensuring every committed financial or stock transaction is synced to disk and survives sudden Android battery pull or OS crash with zero lost commits.
- **NFR-005 (Immutability Guarantee):** Historical stock movements, labour entries, and payments must never be silently overwritten or hard-deleted.

---

## 2. Performance Targets (Android Mid-Range Baseline)

Target baseline device: Mid-range Android smartphone (4 GB RAM, mid-tier ARM64 SoC) with **5,000+ Lots**, **50,000+ Stock Movements**, and **10,000+ Payments**.

- **NFR-006 (Cold Start):** App interactive on dashboard within **<= 1.5 seconds**.
- **NFR-007 (List & Search Latency):** Indexed queries for Lots, Members, Stock Movements, and Member Ledger must complete within **<= 100 ms** (with pagination / lazy loading for large histories).
- **NFR-008 (Frame Stability):** Maintain smooth 60 fps scrolling (`< 16 ms` frame build/raster) by running SQLite on a background isolate (`NativeDatabase.createInBackground` / `drift_flutter`) and using `ListView.builder` with compressed image thumbnails.
- **NFR-009 (Image Storage Efficiency):** Resize/compress lot and attachment photos on import (target max dimension ~1600px, JPEG ~80% quality) to prevent unbounded storage growth while preserving garment detail clarity.

---

## 3. Usability, UI/UX & Accessibility

- **NFR-010 (Android-First Ergonomics):** Primary actions reachable with one hand on compact screens (`360dp` width); minimum touch targets `48×48 dp` for interactive controls (with compact visual heights `40–44 dp` padded to accessible hit areas).
- **NFR-011 (Consistent States):** Every data-driven screen must explicitly handle Loading, Empty, Error (with retry), and Success states using centralized `AppLoader`, `AppEmptyState`, and `AppErrorView`.
- **NFR-012 (WCAG AA Contrast):** Both Light and Dark themes must meet WCAG 2.1 AA contrast ratios (`>= 4.5:1` for normal text, `>= 3:1` for large text and icons).
- **NFR-013 (Dynamic Font Scaling):** UI layouts must tolerate Android system font scaling up to `1.3x` without clipping or `RenderFlex` overflows.
- **NFR-014 (Screen Reader / Semantics):** All icon-only buttons, status badges, and numeric summary cards must provide meaningful semantic labels localized in EN/GU.

---

## 4. Localization & Regional Correctness

- **NFR-015 (Bilingual Parity):** 100% of user-facing strings must exist in both `app_en.arb` and `app_gu.arb` (zero untranslated fallbacks in release builds).
- **NFR-016 (Gujarati Script Rendering):** Bundle **Noto Sans Gujarati** locally so complex conjuncts (*jodakshar*) render cleanly and identically across Android, iOS, Web, Windows, macOS, and Linux without internet access.
- **NFR-017 (Indian Currency & Timezone Formatting):** Format INR with Indian grouping (`₹1,25,000.00` via `en_IN` / `gu_IN` `NumberFormat`) and always render timestamps in `Asia/Kolkata` (`IST`, UTC+05:30).

---

## 5. Security & Privacy (Version 1 & Future Roadmap)

- **NFR-018 (Private Database Storage):** Store the active `.sqlite` database and media files inside OS-enforced private application storage (`getApplicationDocumentsDirectory` / app sandbox). Never store active DB files in Android public external storage (`/sdcard/`).
- **NFR-019 (Explicit User-Initiated Export):** Raw `.sqlite` exports and unencrypted `.zip` full backups occur strictly on explicit user action via OS share/save sheets, with clear on-screen notice that exported files are unencrypted in V1.
- **NFR-020 (Flavor Data Isolation):** `dev` and `prod` builds must use distinct Application IDs, distinct database filenames, and distinct media folders so testing can never corrupt production data.
- **NFR-021 (Future Security Extensibility):** Architecture must cleanly accommodate future enhancements without schema breakage:
  - Optional app-level PIN / biometric lock (`local_auth` + secure storage).
  - Optional password-encrypted `.zip` backup archives.

---

## 6. Maintainability, Portability & Testability

- **NFR-022 (Single Multi-Platform Codebase):** Zero platform-specific hacks inside `domain/` or `presentation/`; platform differences (storage paths, DB connection, file sharing) isolated behind clean abstractions in `core/platform/`.
- **NFR-023 (Schema Migration Safety):** Every database schema version bump must include an automated Drift migration test verifying upgrade from all previous versions with zero data loss.
- **NFR-024 (High Domain Test Coverage):** >= 95% unit test coverage for `StockCalculator`, `LabourCalculator`, `RateResolver`, `LedgerCalculator`, and `BackupValidator`.
- **NFR-025 (Zero Analyzer Issues):** `flutter analyze` must pass with zero errors and zero warnings across all commits.
