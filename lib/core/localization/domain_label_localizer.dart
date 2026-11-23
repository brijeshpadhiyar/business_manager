import 'package:business_manager/core/widgets/app_status_badge.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';

/// Translates domain enums and audit metadata into human-readable localized
/// labels so raw database codes (e.g. `RETURN_GOOD`, `STOCK_MOVEMENT`) never
/// leak into the UI.
abstract final class DomainLabelLocalizer {
  static String movementType(AppLocalizations l10n, StockMovementType type) {
    return switch (type) {
      StockMovementType.issue => l10n.stockTypeIssue,
      StockMovementType.returnGood => l10n.stockTypeReturnGood,
      StockMovementType.returnDamaged => l10n.stockTypeReturnDamaged,
      StockMovementType.settlementLost => l10n.stockTypeLost,
      StockMovementType.settlementShortage => l10n.stockTypeShortage,
      StockMovementType.adjustmentDamagedToGood => l10n.stockTypeRepair,
      StockMovementType.reversal => l10n.stockTypeReversal,
    };
  }

  static AppStatusTone movementTone(StockMovementType type) {
    return switch (type) {
      StockMovementType.issue => AppStatusTone.pending,
      StockMovementType.returnGood ||
      StockMovementType.adjustmentDamagedToGood => AppStatusTone.good,
      StockMovementType.returnDamaged => AppStatusTone.damaged,
      StockMovementType.settlementLost ||
      StockMovementType.settlementShortage => AppStatusTone.info,
      StockMovementType.reversal => AppStatusTone.neutral,
    };
  }

  static String labourBasis(AppLocalizations l10n, LabourBasisType basis) {
    return switch (basis) {
      LabourBasisType.issued => l10n.stockTypeIssue,
      LabourBasisType.receivedGood => l10n.stockTypeReturnGood,
      LabourBasisType.receivedDamaged => l10n.stockTypeReturnDamaged,
      LabourBasisType.reversal => l10n.stockTypeReversal,
    };
  }

  static String billingMode(AppLocalizations l10n, BillingMode mode) {
    return switch (mode) {
      BillingMode.receivedQty => l10n.billingModeReceivedQty,
      BillingMode.givenQty => l10n.billingModeGivenQty,
    };
  }

  static String auditAction(AppLocalizations l10n, String actionType) {
    final normalized = actionType.trim().toUpperCase();
    return switch (normalized) {
      'CREATE' => l10n.auditActionCreate,
      'UPDATE' => l10n.auditActionUpdate,
      'DELETE' || 'SOFT_DELETE' => l10n.auditActionDelete,
      'REVERSAL' => l10n.stockTypeReversal,
      'RATE_OVERRIDE' => l10n.auditActionRateOverride,
      'ARCHIVE' => l10n.lotsStatusArchived,
      'RESTORE' => l10n.auditActionRestore,
      _ => normalized.replaceAll('_', ' '),
    };
  }

  static String auditEntity(AppLocalizations l10n, String entityType) {
    final normalized = entityType.trim().toLowerCase();
    return switch (normalized) {
      'stock_movements' || 'stock_movement' => l10n.navStockMovements,
      'lots' || 'lot' => l10n.navLots,
      'lot_designs' || 'lot_design' => l10n.designsHeading,
      'design_colours' || 'design_colour' => l10n.colourNameLabel,
      'processes' || 'process' => l10n.navProcesses,
      'members' || 'member' || 'workers' => l10n.navWorkers,
      'member_processes' => l10n.assignmentsHeading,
      'member_process_rates' => l10n.ratesHistoryHeading,
      'payments' || 'payment' => l10n.accountingTabPayments,
      'labour_entries' || 'labour_entry' => l10n.accountingTabLabour,
      'worker_ledger_adjustments' => l10n.accountingAdjustmentsLabel,
      'business_profile' => l10n.businessProfileHeading,
      _ => normalized.replaceAll('_', ' '),
    };
  }
}
