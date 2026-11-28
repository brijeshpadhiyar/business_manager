import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/app_status_badge.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
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

  static String paymentType(AppLocalizations l10n, PaymentType type) {
    return switch (type) {
      PaymentType.regular => l10n.accountingPaymentTypeRegular,
      PaymentType.advance => l10n.accountingPaymentTypeAdvance,
      PaymentType.advanceRefund => l10n.accountingPaymentTypeRefund,
      PaymentType.reversal => l10n.stockTypeReversal,
    };
  }

  static String paymentMode(AppLocalizations l10n, PaymentMode mode) {
    return switch (mode) {
      PaymentMode.cash => l10n.accountingModeCash,
      PaymentMode.upi => l10n.accountingModeUpi,
      PaymentMode.bankTransfer => l10n.accountingModeBank,
      PaymentMode.cheque => l10n.accountingModeCheque,
      PaymentMode.other => l10n.accountingModeOther,
    };
  }

  static String auditAction(AppLocalizations l10n, String actionType) {
    final normalized = actionType.trim().toUpperCase();
    return switch (normalized) {
      'CREATE' => l10n.auditActionCreate,
      'UPDATE' => l10n.auditActionUpdate,
      'DELETE' || 'SOFT_DELETE' => l10n.auditActionDelete,
      'DEACTIVATE' => l10n.auditActionDeactivate,
      'REACTIVATE' => l10n.auditActionReactivate,
      'REVERSAL' => l10n.stockTypeReversal,
      'RATE_OVERRIDE' => l10n.auditActionRateOverride,
      'DAMAGED_TO_GOOD_ADJUSTMENT' => l10n.stockTypeRepair,
      'BACKUP_EXPORT' => l10n.auditActionBackupExport,
      'BACKUP_RESTORE' => l10n.auditActionBackupRestore,
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
      'parties' || 'party' => l10n.partiesHeading,
      'dispatch_challans' || 'dispatch_challan' => l10n.dispatchDetailHeading,
      'buyer_returns' || 'buyer_return' => l10n.buyerReturnNewAction,
      'party_payments' || 'party_payment' => l10n.partyTabPayments,
      'lot_direct_costs' => l10n.lotPnlDirectCostsLabel,
      'business_profile' => l10n.businessProfileHeading,
      'backup' => l10n.auditEntityBackup,
      'app_security' => l10n.auditEntityAppSecurity,
      _ => normalized.replaceAll('_', ' '),
    };
  }

  static String timelineTitle(AppLocalizations l10n, LotTimelineEvent e) {
    final qty = e.quantity ?? 0;
    final proc = e.processName ?? l10n.navProcesses;
    final worker = e.workerName ?? l10n.navWorkers;
    return switch (e.traceCode) {
      'lot_created' => l10n.traceLotCreatedTitle(e.lotNumber),
      'mov_issue' => l10n.traceProcessAssignedTitle(proc, qty, worker),
      'mov_return_good' => l10n.traceReturnAcceptedTitle(qty, e.processName ?? ''),
      'mov_return_damaged' => l10n.traceDamagedRecordedTitle(qty),
      'mov_lost' => l10n.traceSettledLostTitle(qty),
      'mov_shortage' => l10n.traceSettledShortageTitle(qty),
      'mov_reversal' => l10n.traceMovementReversedTitle(qty),
      'mov_damaged_repaired' => l10n.traceDamagedRepairedGoodTitle(qty),
      'ret_logged' => l10n.traceReturnedByTitle(
        qty,
        worker,
        e.processName ?? '',
      ),
      'insp_accepted' => (e.traceArgs['isReinsp'] == true)
          ? l10n.traceRepairedReapprovedTitle(qty, e.processName ?? '')
          : l10n.traceApprovedTitle(qty, e.processName ?? ''),
      'insp_rejected' => (e.traceArgs['isReinsp'] == true)
          ? l10n.traceRepairedFailedReinspTitle(qty)
          : l10n.traceRejectedTitle(qty, e.processName ?? ''),
      'rep_logged' => l10n.traceRejectedRepairedTitle(
        qty,
        e.traceArgs['isOriginalWorker'] == true
            ? worker
            : l10n.traceInHouseLabel,
      ),
      'handover_transfer' => l10n.traceDirectTransferTitle(
        qty,
        (e.traceArgs['fromMember'] as String?) ?? l10n.navWorkers,
        (e.traceArgs['toMember'] as String?) ?? l10n.navWorkers,
      ),
      'lot_completed' => l10n.traceLotCompletedTitle(e.lotNumber),
      _ => e.title,
    };
  }

  static String? timelineSubtitle(AppLocalizations l10n, LotTimelineEvent e) {
    final worker = e.workerName ?? '';
    final proc = e.processName ?? '';
    final designColour = '${e.designName ?? ''} ${e.colourName ?? ''}'.trim();
    return switch (e.traceCode) {
      'lot_created' => (e.traceArgs['lotTitle'] as String?) != null
          ? l10n.traceLotCreatedSubtitle(
              e.traceArgs['lotTitle'] as String,
              e.quantity ?? 0,
            )
          : l10n.traceInitialQtySubtitle(e.quantity ?? 0),
      'mov_issue' => l10n.traceRatePerPcSubtitle(
        designColour,
        MoneyFormatter.formatPaise(e.ratePaise ?? 0),
      ),
      'mov_return_good' => l10n.traceEarnedSubtitle(
        worker,
        MoneyFormatter.formatPaise(e.amountPaise ?? 0),
      ),
      'mov_return_damaged' || 'mov_lost' || 'mov_shortage' =>
        '$worker • $proc',
      'mov_reversal' => e.reason,
      'mov_damaged_repaired' => designColour,
      'ret_logged' => (e.traceArgs['isPendingQc'] == true)
          ? l10n.traceReturnPendingQcSubtitle
          : l10n.traceReturnImmediateSubtitle,
      'insp_accepted' => (e.traceArgs['creditWorkerEarnings'] == true)
          ? l10n.traceEarnedAtRateSubtitle(
              worker,
              MoneyFormatter.formatPaise(e.amountPaise ?? 0),
              MoneyFormatter.formatPaise(e.ratePaise ?? 0),
            )
          : l10n.traceInHouseNoEarningSubtitle,
      'insp_rejected' =>
        '$worker • ${l10n.traceZeroPayableLabel}'
            '${e.reason != null ? ' • ${e.reason}' : ''}',
      'rep_logged' => l10n.traceSubmittedReinspSubtitle(proc),
      'handover_transfer' =>
        '$proc • ${e.traceArgs['ref'] ?? ''}',
      'lot_completed' => l10n.traceLotCompletedSubtitle,
      _ => e.subtitle,
    };
  }

  static String feedTitle(AppLocalizations l10n, ProductionHistoryFeedItem item) {
    final proc = item.processName ?? l10n.navProcesses;
    final lotNum = item.lotNumber ?? '';
    final movType = item.traceArgs['movementType'];
    return switch (item.traceCode) {
      'feed_issue' => l10n.traceFeedIssuedTitle(proc, lotNum),
      'feed_movement' => l10n.traceFeedMovementTitle(
        movType is StockMovementType
            ? movementType(l10n, movType)
            : item.badgeLabel,
        lotNum,
      ),
      'feed_return' => l10n.traceFeedReturnTitle(proc, lotNum),
      'feed_reinspection' => l10n.traceFeedReinspectionTitle(lotNum, proc),
      'feed_inspection' => l10n.traceFeedInspectionTitle(lotNum, proc),
      _ => item.title,
    };
  }

  static String feedSubtitle(
    AppLocalizations l10n,
    ProductionHistoryFeedItem item,
  ) {
    if (item.traceCode == 'feed_reinspection' ||
        item.traceCode == 'feed_inspection') {
      return l10n.traceFeedInspectionSubtitle(
        item.workerName ?? '-',
        (item.traceArgs['acc'] as int?) ?? 0,
        (item.traceArgs['rej'] as int?) ?? 0,
      );
    }
    return item.subtitle;
  }

  static String feedBadge(AppLocalizations l10n, ProductionHistoryFeedItem item) {
    final movType = item.traceArgs['movementType'];
    return switch (item.badgeCode) {
      'issued' => l10n.traceBadgeIssued,
      'movement' => movType is StockMovementType
          ? movementType(l10n, movType)
          : item.badgeLabel,
      'pending_qc' => l10n.traceBadgePendingQc,
      'returned' => l10n.traceBadgeReturned,
      'reapproved' => l10n.traceBadgeReapproved,
      'inspected' => l10n.traceBadgeInspected,
      _ => item.badgeLabel,
    };
  }

  static String transactionTitle(
    AppLocalizations l10n,
    ProductionTransactionDetail d,
  ) {
    final movType = d.traceArgs['movementType'];
    return switch (d.titleCode) {
      'stock_movement' => l10n.traceTxnStockMovementTitle(
        movType is StockMovementType
            ? movementType(l10n, movType)
            : d.statusLabel,
      ),
      'production_return' => l10n.traceProductionReturnLink,
      'reinspection' => l10n.traceTxnReinspectionTitle,
      'inspection' => l10n.traceTxnInspectionTitle,
      'rejection' => l10n.traceTxnRejectionTitle,
      'repair' => l10n.traceTxnRepairTitle,
      'handover' => l10n.traceTxnHandoverTitle(
        (d.traceArgs['handoverType'] as String?) ?? d.statusLabel,
      ),
      'labour_entry' => l10n.traceTxnLabourTitle(
        _localizeBasisString(l10n, d.traceArgs['basis'] as String?),
      ),
      'payment' => l10n.traceTxnPaymentTitle(
        _localizePaymentTypeString(
          l10n,
          d.traceArgs['paymentType'] as String?,
        ),
      ),
      'adjustment' => l10n.traceTxnAdjustmentTitle(
        (d.traceArgs['adjustmentType'] as String?) ?? d.statusLabel,
      ),
      _ => d.title,
    };
  }

  static String transactionStatus(
    AppLocalizations l10n,
    ProductionTransactionDetail d,
  ) {
    final movType = d.traceArgs['movementType'];
    if (d.titleCode == 'stock_movement' && movType is StockMovementType) {
      return movementType(l10n, movType);
    }
    return switch (d.statusCode) {
      'pending_qc' => l10n.traceBadgePendingQc,
      'returned' => l10n.traceBadgeReturned,
      'reapproved' => l10n.traceBadgeReapproved,
      'inspected' => l10n.traceBadgeInspected,
      'payable' => l10n.traceBadgePayable,
      'informational' => l10n.traceBadgeInformational,
      _ => _localizeStatusFallback(l10n, d.statusLabel),
    };
  }

  static String relatedLinkLabel(
    AppLocalizations l10n,
    ProductionRelatedLink link,
  ) {
    return switch (link.code) {
      'parent_issue' => l10n.traceParentIssueLink,
      'labour_entry' => l10n.traceLabourEntryLink(
        _localizeBasisString(l10n, link.args['basis'] as String?),
      ),
      'inspection' => l10n.traceInspectionLink(
        (link.args['acc'] as int?) ?? 0,
        (link.args['rej'] as int?) ?? 0,
      ),
      'reinspection' => l10n.traceReinspectionLink(
        (link.args['acc'] as int?) ?? 0,
      ),
      'production_return' => l10n.traceProductionReturnLink,
      'worker_earning' => l10n.traceWorkerEarningLink,
      'original_rejection' => l10n.traceOriginalRejectionLink,
      'inspection_event' => l10n.traceInspectionEventLink,
      'repair' => l10n.traceRepairLink((link.args['qty'] as int?) ?? 0),
      'linked_movement' => l10n.traceLinkedMovementLink,
      _ => link.label,
    };
  }

  static String _localizeBasisString(AppLocalizations l10n, String? raw) {
    if (raw == null || raw.isEmpty) return '';
    for (final b in LabourBasisType.values) {
      if (b.dbValue == raw) return labourBasis(l10n, b);
    }
    return raw;
  }

  static String _localizePaymentTypeString(AppLocalizations l10n, String? raw) {
    if (raw == null || raw.isEmpty) return '';
    for (final t in PaymentType.values) {
      if (t.dbValue == raw) return paymentType(l10n, t);
    }
    return raw;
  }

  static String _localizeStatusFallback(AppLocalizations l10n, String raw) {
    for (final m in PaymentMode.values) {
      if (m.dbValue == raw) return paymentMode(l10n, m);
    }
    return raw;
  }
}
