import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Shared canonical row-to-entity mappers for core ledger and rate tables.
///
/// Centralizing these mappers prevents subtle field-omission drift (e.g.
/// missing `jobProcessId`) across repositories and diagnostics services.
abstract final class LedgerRowMappers {
  static StockMovementEntity stockMovement(StockMovementRow row) =>
      StockMovementEntity(
        id: row.id,
        lotId: row.lotId,
        lotDesignId: row.lotDesignId,
        designColourId: row.designColourId,
        processId: row.processId,
        memberId: row.memberId,
        parentIssueId: row.parentIssueId,
        jobProcessId: row.jobProcessId,
        reversesMovementId: row.reversesMovementId,
        clientRequestId: row.clientRequestId,
        movementType: StockMovementType.fromDbValue(row.movementType),
        quantity: row.quantity,
        sourceRateId: row.sourceRateId,
        appliedRatePaise: row.appliedRatePaise,
        isRateOverridden: row.isRateOverridden == 1,
        overrideReason: row.overrideReason,
        lockedBillingMode: row.lockedBillingMode != null
            ? BillingMode.fromDbValue(row.lockedBillingMode!)
            : null,
        lockedIncludeDamaged: row.lockedIncludeDamaged == 1,
        reason: row.reason,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static LabourEntryEntity labourEntry(LabourEntryRow row) => LabourEntryEntity(
    id: row.id,
    stockMovementId: row.stockMovementId,
    reversesLabourEntryId: row.reversesLabourEntryId,
    memberId: row.memberId,
    processId: row.processId,
    lotId: row.lotId,
    basisType: LabourBasisType.fromDbValue(row.basisType),
    quantity: row.quantity,
    ratePaise: row.ratePaise,
    amountPaise: row.amountPaise,
    isPayable: row.isPayable == 1,
    transactionAt: row.transactionAt,
    recordedAt: row.recordedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  static PaymentEntity payment(PaymentRow row) => PaymentEntity(
    id: row.id,
    memberId: row.memberId,
    paymentType: PaymentType.fromDbValue(row.paymentType),
    reversesPaymentId: row.reversesPaymentId,
    clientRequestId: row.clientRequestId,
    amountPaise: row.amountPaise,
    paymentMode: PaymentMode.fromDbValue(row.paymentMode),
    referenceNo: row.referenceNo,
    reason: row.reason,
    notes: row.notes,
    transactionAt: row.transactionAt,
    recordedAt: row.recordedAt,
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  static WorkerAdjustmentEntity workerAdjustment(
    WorkerLedgerAdjustmentRow row,
  ) => WorkerAdjustmentEntity(
    id: row.id,
    memberId: row.memberId,
    adjustmentType: WorkerAdjustmentType.fromDbValue(row.adjustmentType),
    reversesAdjustmentId: row.reversesAdjustmentId,
    clientRequestId: row.clientRequestId,
    amountPaise: row.amountPaise,
    reason: row.reason,
    notes: row.notes,
    transactionAt: row.transactionAt,
    recordedAt: row.recordedAt,
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  static MemberProcessRateEntity memberProcessRate(MemberProcessRateRow row) =>
      MemberProcessRateEntity(
        id: row.id,
        memberId: row.memberId,
        processId: row.processId,
        ratePaise: row.ratePaise,
        effectiveFrom: row.effectiveFrom,
        effectiveTo: row.effectiveTo,
        notes: row.notes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
