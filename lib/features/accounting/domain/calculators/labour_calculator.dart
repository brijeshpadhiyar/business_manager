import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure Dart labour calculation engine enforcing StitchFlow Final Worker
/// Payment Business Rules:
///
/// - **Rule 1 (Accepted-Only Earnings):** Worker earnings are calculated
///   exclusively as `acceptedQuantity * historicalAssignedRatePaise`.
///   Never calculate earnings from assigned (`ISSUE`) quantity or total
///   uninspected returned quantity.
/// - **Rule 3 (Rejected Exclusion & Re-Approval):** Rejected/damaged pieces
///   NEVER generate worker earnings, regardless of legacy
///   `includeDamagedInLabour` settings. Repaired pieces generate earnings ONLY
///   for newly accepted quantities via an immutable re-approval transaction
///   when repaired by the original worker.
/// - **Rule 5 (Historical Rate Protection):** Always multiplies by the rate
///   snapshotted when the work was assigned, never current master rates.
/// - **Exact integer paise arithmetic (`quantity * lockedRatePaise`).**
final class LabourCalculator {
  const LabourCalculator();

  /// Effective billing mode for all new transactions is strictly
  /// [BillingMode.receivedQty] (Accepted Quantity). Legacy overrides are
  /// retained in storage for historical audit compatibility only and never
  /// alter new earnings calculations.
  BillingMode resolveEffectiveBillingMode({
    required BillingMode globalDefault,
    required BillingMode? processOverride,
  }) {
    return BillingMode.receivedQty;
  }

  /// Plans the informational-only labour entry recorded with a new `ISSUE`.
  ///
  /// Per Final Rule 1, `ISSUE` movements NEVER generate payable worker earnings
  /// (`isPayable` is always `false`, regardless of legacy `lockedBillingMode`).
  PlannedLabourEntry planForIssue({
    required int quantity,
    required int appliedRatePaise,
    required BillingMode lockedBillingMode,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be > 0.');
    }
    if (appliedRatePaise < 0) {
      throw ArgumentError.value(
        appliedRatePaise,
        'appliedRatePaise',
        'Must be >= 0.',
      );
    }
    return PlannedLabourEntry(
      basisType: LabourBasisType.issued,
      quantity: quantity,
      ratePaise: appliedRatePaise,
      amountPaise: quantity * appliedRatePaise,
      isPayable: false,
    );
  }

  /// Plans the labour entry (if any) for an inspection/settlement movement.
  ///
  /// Enforces Final Rules 1 & 3:
  /// - `returnGood` (accepted quantity): ALWAYS payable as
  ///   `quantity * lockedRatePaise`.
  /// - `returnDamaged` (rejected/damaged): NEVER payable (`null`), even if
  ///   legacy `lockedIncludeDamaged` was true.
  /// - `lost` / `shortage` / other types: NEVER payable (`null`).
  PlannedLabourEntry? planForSettlement({
    required StockMovementType movementType,
    required int quantity,
    required int lockedRatePaise,
    required BillingMode lockedBillingMode,
    required bool lockedIncludeDamaged,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be > 0.');
    }
    if (lockedRatePaise < 0) {
      throw ArgumentError.value(
        lockedRatePaise,
        'lockedRatePaise',
        'Must be >= 0.',
      );
    }

    switch (movementType) {
      case StockMovementType.returnGood:
        return PlannedLabourEntry(
          basisType: LabourBasisType.receivedGood,
          quantity: quantity,
          ratePaise: lockedRatePaise,
          amountPaise: quantity * lockedRatePaise,
          isPayable: true,
        );
      case StockMovementType.returnDamaged:
      case StockMovementType.settlementLost:
      case StockMovementType.settlementShortage:
      case StockMovementType.adjustmentDamagedToGood:
      case StockMovementType.issue:
      case StockMovementType.reversal:
        return null;
    }
  }

  /// Plans the payable labour entry for newly re-approved repaired pieces
  /// (Final Rule 3).
  ///
  /// Generates earnings strictly for [acceptedQuantity] at the original
  /// assignment's [lockedRatePaise] when [creditOriginalWorker] is true
  /// (repaired by the original worker). Returns `null` when repaired in-house
  /// without crediting the worker or when [acceptedQuantity] is 0.
  PlannedLabourEntry? planForRepairReapproval({
    required int acceptedQuantity,
    required int lockedRatePaise,
    required bool creditOriginalWorker,
  }) {
    if (acceptedQuantity < 0) {
      throw ArgumentError.value(
        acceptedQuantity,
        'acceptedQuantity',
        'Must be >= 0.',
      );
    }
    if (lockedRatePaise < 0) {
      throw ArgumentError.value(
        lockedRatePaise,
        'lockedRatePaise',
        'Must be >= 0.',
      );
    }
    if (acceptedQuantity == 0 || !creditOriginalWorker) {
      return null;
    }
    return PlannedLabourEntry(
      basisType: LabourBasisType.receivedGood,
      quantity: acceptedQuantity,
      ratePaise: lockedRatePaise,
      amountPaise: acceptedQuantity * lockedRatePaise,
      isPayable: true,
    );
  }

  /// Plans the offsetting negative labour reversal entry for a reversed
  /// movement's original labour entry.
  PlannedLabourEntry planReversalForEntry(LabourEntryEntity original) {
    return PlannedLabourEntry(
      basisType: LabourBasisType.reversal,
      quantity: -original.quantity,
      ratePaise: original.ratePaise,
      amountPaise: -original.amountPaise,
      isPayable: original.isPayable,
      reversesLabourEntryId: original.id,
    );
  }
}
