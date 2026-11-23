# Development Guidelines

This document defines mandatory engineering standards for implementing **Business Manager (`બિઝનેસ મેનેજર`)**. Every developer and AI agent working on this repository must follow these guidelines.

---

## 1. Core Architectural Rules

1. **Feature-First Clean Architecture:**
   - Every business feature lives under `lib/features/<feature_name>/` with three strict layers: `domain/`, `data/`, and `presentation/`.
   - **Dependency Rule:** `presentation` → `domain` ← `data`.
   - `domain/` must remain **pure Dart** (zero imports of `package:flutter`, `package:drift`, `package:flutter_bloc`, or platform plugins).
2. **Zero Business Logic in BLoCs or Widgets:**
   - All stock, labour, pricing, and ledger calculations must live in pure, deterministic domain services/calculators (e.g., `StockCalculator`, `LabourCalculator`, `RateResolver`, `LedgerCalculator`).
   - BLoCs/Cubits only coordinate UseCases, manage UI state transitions, and map failures to localized UI messages.
3. **Zero Direct Database Access from UI:**
   - Widgets and BLoCs never import Drift tables, DAOs, or `AppDatabase`. They talk exclusively to `domain/usecases/` (which depend on abstract `domain/repositories/`).
4. **Offline-First & Backend-Free V1:**
   - No HTTP clients, Firebase, Supabase, or online auth SDKs in V1. Keep repository interfaces async (`Future`/`Stream`) and clean so a remote sync data source can be added in V2 without changing `domain/` or `presentation/`.

---

## 2. Database & Financial Integrity Rules

1. **Integer Paise for All Money:**
   - Never use `double` or SQLite `REAL` for rates, prices, labour amounts, or payments. Always use `int` representing **paise** (`₹20.00` = `2000`).
2. **Append-Only Transactions:**
   - Never mutate or hard-delete historical `stock_movements`, `labour_entries`, or `payments`.
   - Corrections must be performed via explicit reversal/compensating entries linked to the original transaction ID and logged in `audit_logs`.
3. **Atomic Multi-Table Writes:**
   - Any operation touching multiple tables (e.g., recording a stock return + generating a labour entry + writing an audit log) must execute inside a single Drift `transaction(() async { ... })`.
4. **UTC Storage, `Asia/Kolkata` Display:**
   - Store all timestamps as UTC milliseconds since epoch (`INTEGER`).
   - Always resolve effective business dates (`YYYY-MM-DD`) by converting `transactionAt` to `Asia/Kolkata` before querying `member_process_rates`.

---

## 3. UI, Design System & Localization Standards

1. **Official Material 3 Foundation (`material_ui: ^1.11.1`):**
   - Use Flutter's official decoupled Material 3 package (`package:material_ui/material_ui.dart`, published by `flutter.dev`) as the UI foundation, wrapped cleanly inside our centralized `lib/core/widgets/` library (`AppButton`, `AppCard`, `AppText`, `AppScaffold`, `AppTextField`, `AppDropdown`, etc.).
   - Avoid third-party UI kits or duplicate widget implementations.
2. **Design Tokens Only:**
   - Never hardcode raw hex colors, arbitrary paddings, font sizes, or border radii inside feature screens. Always reference `AppSpacing`, `AppRadius`, `AppSizing`, and `Theme.of(context).colorScheme` / `textTheme`.
3. **Zero Hardcoded Strings:**
   - Every visible label, button, validation error, tooltip, status badge, dialog, and empty state must come from `AppLocalizations.of(context)` (`lib/l10n/app_en.arb` and `lib/l10n/app_gu.arb`).
   - When adding a key to `app_en.arb`, add the corresponding Gujarati translation in `app_gu.arb` in the same commit.
4. **Android-First Responsive Design:**
   - Every screen must be ergonomic on a 360dp-wide Android phone first, then adapt cleanly to tablet (`>= 600dp`) and desktop (`>= 1024dp`) layouts.

---

## 4. Dart & Code Generation Workflow

1. **Strict Static Analysis:**
   - Run `flutter analyze` before every commit; zero errors and zero warnings allowed.
2. **Code Generation (`build_runner` + `gen-l10n`):**
   - Run `dart run build_runner build --delete-conflicting-outputs` whenever modifying `@freezed`, `@JsonSerializable`, `@DriftDatabase`, `@DriftAccessor`, or `@injectable` files.
   - Run `flutter gen-l10n` after editing `.arb` files.
   - Never hand-edit `*.g.dart`, `*.freezed.dart`, or `*.config.dart`.
3. **Naming Conventions:**
   - Files: `snake_case.dart`
   - Classes / Enums / Extensions: `UpperCamelCase`
   - Variables / Methods / Parameters: `lowerCamelCase`
   - BLoC Events: past/imperative verb (`StockMovementSubmitted`, `LotPhotosRequested`)
   - BLoC States: `@freezed` sealed unions or immutable state data classes with explicit `status` enum.

---

## 5. Git, Branching & PR Checklist

- **Conventional Commits:** `feat(stock): ...`, `fix(labour): ...`, `docs(schema): ...`, `test(pricing): ...`, `refactor(ui): ...`.
- **Mandatory Pre-Merge Checklist:**
  - [ ] `flutter analyze` passes with 0 issues.
  - [ ] `flutter test` passes (all unit, DB, BLoC, and widget tests).
  - [ ] Both `app_en.arb` and `app_gu.arb` updated (zero hardcoded strings).
  - [ ] Light and Dark themes verified.
  - [ ] Android flavor `dev` tested without touching `prod` DB.
  - [ ] `CHANGELOG.md` updated for user-facing changes.
