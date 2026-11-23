# 05 — System Architecture

## 1. Architectural Pattern: Feature-First Clean Architecture

The application follows **Feature-First Clean Architecture** with strict unidirectional dependencies:

```mermaid
flowchart TD
    UI["Presentation Layer\n(Flutter Pages, Widgets, BLoCs/Cubits)"]
    DOM["Domain Layer (Pure Dart)\n(Entities, Repositories, UseCases, Pure Calculators)"]
    DATA["Data Layer\n(Repository Impls, Drift DAOs, Local File Store, Mappers)"]
    INFRA["Local Infrastructure\n(Drift SQLite DB, Private App Storage, SharedPreferences)"]

    UI --> DOM
    DATA --> DOM
    DATA --> INFRA
```

### Layer Responsibilities

1. **Presentation Layer (`features/<name>/presentation/`):**
   - Renders UI using centralized Material 3 widgets (`lib/core/widgets/`).
   - Uses `flutter_bloc` (`Bloc` for event-driven workflows, `Cubit` for simple UI/filter state).
   - **Strictly prohibited:** Direct DB calls, Drift imports, or business math inside widgets/BLoCs.
2. **Domain Layer (`features/<name>/domain/`):**
   - **100% Pure Dart** (no `flutter`, `drift`, `flutter_bloc`, or platform imports).
   - Contains immutable `@freezed` Entities, abstract Repository interfaces, single-responsibility UseCases, Value Objects, Failure/Result types, and pure deterministic **Domain Calculators**:
     - `StockCalculator` (in-house physical stock, per-process pending, damaged bucket, over-issue/over-return guards)
     - `LabourCalculator` (Given vs. Received, Good-only vs. Damaged-inclusive, anti-double-counting)
     - `RateResolver` (`transactionAt` IST date lookup, overlap checks, rate locking)
     - `LedgerCalculator` (earned labour, regular/advance payments, advance refunds, outstanding payable vs. advance credit)
3. **Data Layer (`features/<name>/data/`):**
   - Implements Domain Repository interfaces.
   - Coordinates Drift DAOs, atomic SQLite transactions, local attachment file storage, and `audit_logs` emission.
   - Maps Drift `DataClass` / `Companion` rows to/from Domain entities.

---

## 2. Core Cross-Cutting Modules (`lib/core/`)

- **`core/config/`:** Flavor configuration (`AppFlavor`, `AppConfig`, DB name, logging toggle, media subfolder).
- **`core/database/`:** `AppDatabase` (`@DriftDatabase`), connection factory (`connection_native.dart` / `connection_web.dart`), schema migrations, and shared audit helper.
- **`core/di/`:** `get_it` + `injectable` registration (`injection.dart`, `injection.config.dart`).
- **`core/design_system/`:** Theme (`AppTheme`), color tokens, typography (with Noto Sans Gujarati), spacing, radius, sizing.
- **`core/widgets/`:** Centralized reusable Material 3 widgets (`AppScaffold`, `AppButton`, `AppCard`, `AppDataTable`, etc.).
- **`core/router/`:** `go_router` route tree, responsive shell navigation (BottomNav / NavigationRail / Sidebar).
- **`core/utils/`:** `IstDateTimeHelper` (UTC ↔ `Asia/Kolkata`), `MoneyFormatter` (paise ↔ `₹`), `IdGenerator` (UUIDv7).
- **`core/platform/`:** Platform abstractions for private file storage, photo compression, raw `.sqlite` export, and `.zip` backup/restore.

---

## 3. Data Flow Example: Recording a Partial Return

```mermaid
sequenceDiagram
    participant Page as ReturnStockPage (UI)
    participant Bloc as StockMovementBloc
    participant UC as RecordStockSettlementUseCase
    participant Calc as StockCalculator & LabourCalculator
    participant Repo as StockMovementRepositoryImpl
    participant DB as Drift SQLite (Transaction)

    Page->>Bloc: SubmitSettlement(parentIssueId, good: 95, damaged: 3, lost: 2)
    Bloc->>UC: call(params)
    UC->>Repo: executeSettlementAtomically(params, StockCalculator, LabourCalculator)
    Repo->>DB: BEGIN TRANSACTION
    Repo->>DB: SELECT parent issue + existing active settlements
    DB-->>Repo: issueAggregate
    Repo->>Calc: validateSettlement(issueAggregate, 95, 3, 2)
    Calc-->>Repo: Valid (pending -> 0)
    Repo->>Calc: computeLabour(issueAggregate.lockedRate, lockedBillingMode, lockedIncludeDamaged)
    Calc-->>Repo: LabourEntry(qty: 95, amount: 190000 paise, isPayable: true)
    Repo->>DB: INSERT movements + labour_entries + audit_logs -> COMMIT
    DB-->>Repo: success
    Repo-->>UC: Right(SettlementResult)
    UC-->>Bloc: Right(SettlementResult)
    Bloc-->>Page: StockMovementState.success()
```

---

## 4. Future Backend Extensibility (Without V1 Bloat)

- All repositories expose `Future` / `Stream` interfaces returning Domain entities and typed `Failure` results.
- All primary keys use **UUIDv7** (`TEXT`) rather than auto-increment integers, preventing ID collisions if multi-device sync is ever added in V2+.
- All timestamps are stored in **UTC**, and all transactional tables are **append-only** with `updatedAt` and `deletedAt`, making future incremental delta-sync straightforward without rewriting `domain/` or `presentation/`.
- **Zero** networking, REST, Firebase, or Supabase code is introduced in V1.
