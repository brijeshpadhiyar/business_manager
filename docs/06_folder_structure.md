# 06 — Folder Structure

The codebase uses a **feature-first Clean Architecture** structure so each business capability is self-contained, testable, and easy to navigate.

```text
business_manager/
├── config/                               # Flavor build-time configs (--dart-define-from-file)
│   ├── dev.json
│   └── prod.json
├── assets/
│   ├── fonts/
│   │   ├── NotoSansGujarati-Regular.ttf
│   │   ├── NotoSansGujarati-Medium.ttf
│   │   ├── NotoSansGujarati-SemiBold.ttf
│   │   └── NotoSansGujarati-Bold.ttf
│   └── images/
│       └── app_logo_default.png
├── docs/                                 # Technical blueprint, audit & safeguards (00..24)
├── lib/
│   ├── main_dev.dart                     # Dev flavor entrypoint
│   ├── main_prod.dart                    # Prod flavor entrypoint
│   ├── app.dart                          # Root MaterialApp.router, Theme & Locale wiring
│   ├── l10n/
│   │   ├── app_en.arb                    # English localization template
│   │   ├── app_gu.arb                    # Gujarati localization
│   │   └── generated/                    # gen-l10n output (synthetic-package: false)
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   └── app_flavor.dart
│   │   ├── database/
│   │   │   ├── app_database.dart         # @DriftDatabase root
│   │   │   ├── connection/
│   │   │   │   ├── connection.dart       # Conditional export
│   │   │   │   ├── connection_native.dart
│   │   │   │   ├── connection_web.dart
│   │   │   │   └── connection_unsupported.dart
│   │   │   ├── tables/                   # Drift table definitions (one file per entity group)
│   │   │   ├── daos/                     # Drift DAOs
│   │   │   └── migrations/               # Schema migration logic & helpers
│   │   ├── design_system/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_spacing.dart
│   │   │   ├── app_radius.dart
│   │   │   ├── app_sizing.dart
│   │   │   └── app_theme.dart
│   │   ├── di/
│   │   │   ├── injection.dart
│   │   │   └── injection.config.dart
│   │   ├── error/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── platform/
│   │   │   ├── storage_service.dart
│   │   │   ├── media_service.dart
│   │   │   └── file_export_service.dart
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   ├── route_paths.dart
│   │   │   └── adaptive_shell_scaffold.dart
│   │   ├── utils/
│   │   │   ├── ist_datetime_helper.dart
│   │   │   ├── money_formatter.dart
│   │   │   └── id_generator.dart
│   │   └── widgets/                      # Centralized Material 3 widgets (19 here + AdaptiveShellScaffold in core/router/ = 20)
│   │       ├── app_scaffold.dart
│   │       ├── app_card.dart
│   │       ├── app_text.dart
│   │       ├── app_heading.dart
│   │       ├── app_button.dart
│   │       ├── app_icon_button.dart
│   │       ├── app_text_field.dart
│   │       ├── app_dropdown.dart
│   │       ├── app_date_picker.dart
│   │       ├── app_checkbox.dart
│   │       ├── app_radio.dart
│   │       ├── app_switch.dart
│   │       ├── app_dialog.dart
│   │       ├── app_bottom_sheet.dart
│   │       ├── app_loader.dart
│   │       ├── app_empty_state.dart
│   │       ├── app_error_view.dart
│   │       ├── app_status_badge.dart
│   │       ├── app_data_table.dart
│   │       └── widgets.dart              # Barrel export
│   └── features/
│       ├── dashboard/
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       ├── lots/                         # Lots, Designs, Colours, Lot Photos
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   └── usecases/
│       │   ├── data/
│       │   │   ├── mappers/
│       │   │   └── repositories/
│       │   └── presentation/
│       │       ├── bloc/
│       │       ├── pages/
│       │       └── widgets/
│       ├── processes/                    # Dynamic Production Processes & billing overrides
│       ├── members/                      # Members, Member-Process links, Historical Rates
│       ├── stock_movements/              # Issue, Partial Returns, Damaged/Lost/Shortage, Adjustments
│       │   ├── domain/
│       │   │   ├── calculators/          # StockCalculator, RateResolver
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   └── usecases/
│       │   ├── data/
│       │   └── presentation/
│       ├── labour/                       # Labour entries & LabourCalculator
│       ├── payments/                     # Regular, Advance, Advance Refund, Reversal
│       ├── ledger/                       # Member Ledger & LedgerCalculator
│       ├── reports/                      # Lot, Process, Worker, Damaged, Cashflow reports
│       ├── audit/                        # Audit log viewer & query service
│       ├── backup_restore/               # Raw .sqlite export & full .zip backup/restore
│       └── settings/                     # Business profile, theme, locale, billing defaults
├── test/
│   ├── unit/
│   │   ├── stock_calculator_test.dart
│   │   ├── labour_calculator_test.dart
│   │   ├── rate_resolver_test.dart
│   │   ├── ledger_calculator_test.dart
│   │   └── backup_validator_test.dart
│   ├── database/
│   │   ├── drift_schema_integrity_test.dart
│   │   └── drift_migration_test.dart
│   ├── bloc/
│   ├── widget/
│   └── integration/
├── l10n.yaml
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── CHANGELOG.md
├── DEVELOPMENT_GUIDELINES.md
└── AGENT_RULES.md
```

## Ownership & Import Boundary Rules

- `lib/features/<A>/domain/` may import `lib/core/error/`, `lib/core/utils/`, and other feature **domain** entities/interfaces only.
- `lib/features/<A>/presentation/` may import `lib/core/widgets/`, `lib/core/design_system/`, `lib/l10n/`, and its own `domain/` layer—never `data/` or `core/database/`.
- Feature-specific complex widgets (e.g., `PartialReturnBreakdownCard`, `MemberRateTimelineTile`) stay inside `features/<name>/presentation/widgets/`, not `core/widgets/`.
