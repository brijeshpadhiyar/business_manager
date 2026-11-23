import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure Dart labour calculation engine implementing `docs/10_labour_calculation_rules.md`.
///
/// Guarantees:
/// - Default Pay on Received Good Quantity (`RECEIVED_QTY`, `includeDamaged = false`).
/// - Supports per-process override (`GIVEN_QTY` / `RECEIVED_QTY`) and optional
///   damaged inclusion (`lockedIncludeDamaged = true`), locked on `ISSUE` creation.
/// - Lost & shortage pieces are excluded from labour by default.
/// - Zero double-counting: an `ISSUE` and its `RETURN_GOOD` are never both payable.
/// - Exact integer paise arithmetic (`quantity * appliedRatePaise`).
final class LabourCalculator {
  const LabourCalculator();

  /// Resolves the effective billing mode for a new `ISSUE` using the process
  /// override if configured, otherwise falling back to the global business default.
  BillingMode resolveEffectiveBillingMode({
    required BillingMode globalDefault,
    required BillingMode? processOverride,
  }) {
    return processOverride ?? globalDefault;
  }

  /// Plans the labour entry to insert atomically with a new `ISSUE` movement.
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
      isPayable: lockedBillingMode == BillingMode.givenQty,
    );
  }

  /// Plans the labour entry (if any) to insert atomically with a child settlement.
  /// Always uses the parent issue's locked rate, locked billing mode, and
  /// locked damaged-inclusion flag.
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
          isPayable: lockedBillingMode == BillingMode.receivedQty,
        );
      case StockMovementType.returnDamaged:
        if (lockedBillingMode == BillingMode.receivedQty &&
            lockedIncludeDamaged) {
          return PlannedLabourEntry(
            basisType: LabourBasisType.receivedDamaged,
            quantity: quantity,
            ratePaise: lockedRatePaise,
            amountPaise: quantity * lockedRatePaise,
            isPayable: true,
          );
        }
        return null;
      case StockMovementType.settlementLost:
      case StockMovementType.settlementShortage:
      case StockMovementType.adjustmentDamagedToGood:
      case StockMovementType.issue:
      case StockMovementType.reversal:
        return null;
    }
  }

  /// Plans the offsetting negative labour reversal entry for a reversed movement's
  /// original labour entry.
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
