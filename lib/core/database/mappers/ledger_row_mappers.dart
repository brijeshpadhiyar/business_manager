import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
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

  static PartyEntity party(PartyRow row) => PartyEntity(
    id: row.id,
    name: row.name,
    phone: row.phone,
    address: row.address,
    partyType: PartyType.fromDbValue(row.partyType),
    gstin: row.gstin,
    openingBalancePaise: row.openingBalancePaise,
    notes: row.notes,
    isActive: row.isActive == 1,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  static DispatchChallanEntity dispatchChallan(DispatchChallanRow row) =>
      DispatchChallanEntity(
        id: row.id,
        challanNumber: row.challanNumber,
        partyId: row.partyId,
        reversesChallanId: row.reversesChallanId,
        clientRequestId: row.clientRequestId,
        grossAmountPaise: row.grossAmountPaise,
        discountPaise: row.discountPaise,
        otherChargesPaise: row.otherChargesPaise,
        netAmountPaise: row.netAmountPaise,
        reason: row.reason,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static DispatchItemEntity dispatchItem(
    DispatchItemRow row, {
    String lotNumber = '',
    String designName = '',
    String colourName = '',
    String? colourHex,
  }) => DispatchItemEntity(
    id: row.id,
    challanId: row.challanId,
    lotId: row.lotId,
    lotDesignId: row.lotDesignId,
    designColourId: row.designColourId,
    quantity: row.quantity,
    ratePaise: row.ratePaise,
    lineTotalPaise: row.lineTotalPaise,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    lotNumber: lotNumber,
    designName: designName,
    colourName: colourName,
    colourHex: colourHex,
  );

  static BuyerReturnEntity buyerReturn(BuyerReturnRow row) => BuyerReturnEntity(
    id: row.id,
    returnNumber: row.returnNumber,
    partyId: row.partyId,
    challanId: row.challanId,
    reversesReturnId: row.reversesReturnId,
    clientRequestId: row.clientRequestId,
    creditAmountPaise: row.creditAmountPaise,
    reason: row.reason,
    notes: row.notes,
    transactionAt: row.transactionAt,
    recordedAt: row.recordedAt,
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  static BuyerReturnItemEntity buyerReturnItem(
    BuyerReturnItemRow row, {
    String lotNumber = '',
    String designName = '',
    String colourName = '',
  }) => BuyerReturnItemEntity(
    id: row.id,
    buyerReturnId: row.buyerReturnId,
    dispatchItemId: row.dispatchItemId,
    lotId: row.lotId,
    lotDesignId: row.lotDesignId,
    designColourId: row.designColourId,
    returnCondition: BuyerReturnCondition.fromDbValue(row.returnCondition),
    quantity: row.quantity,
    ratePaise: row.ratePaise,
    lineCreditPaise: row.lineCreditPaise,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    lotNumber: lotNumber,
    designName: designName,
    colourName: colourName,
  );

  static PartyPaymentEntity partyPayment(PartyPaymentRow row) =>
      PartyPaymentEntity(
        id: row.id,
        partyId: row.partyId,
        challanId: row.challanId,
        reversesPaymentId: row.reversesPaymentId,
        clientRequestId: row.clientRequestId,
        paymentType: PartyPaymentType.fromDbValue(row.paymentType),
        paymentMode: PartyPaymentMode.fromDbValue(row.paymentMode),
        amountPaise: row.amountPaise,
        referenceNo: row.referenceNo,
        reason: row.reason,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static LotDirectCostEntity lotDirectCost(LotDirectCostRow row) =>
      LotDirectCostEntity(
        id: row.id,
        lotId: row.lotId,
        reversesCostId: row.reversesCostId,
        clientRequestId: row.clientRequestId,
        category: LotCostCategory.fromDbValue(row.category),
        description: row.description,
        amountPaise: row.amountPaise,
        reason: row.reason,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static WorkshopExpenseEntity workshopExpense(WorkshopExpenseRow row) =>
      WorkshopExpenseEntity(
        id: row.id,
        category: ExpenseCategory.fromDbValue(row.category),
        title: row.title,
        payeeName: row.payeeName,
        amountPaise: row.amountPaise,
        paymentStatus: ExpensePaymentStatus.fromDbValue(row.paymentStatus),
        paymentMode: row.paymentMode != null
            ? PaymentMode.fromDbValue(row.paymentMode!)
            : null,
        referenceNo: row.referenceNo,
        reversesExpenseId: row.reversesExpenseId,
        clientRequestId: row.clientRequestId,
        reason: row.reason,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static CashbookEntryEntity cashbookEntry(CashbookEntryRow row) =>
      CashbookEntryEntity(
        id: row.id,
        entryType: CashbookEntryType.fromDbValue(row.entryType),
        accountBucket: CashbookAccountBucket.fromDbValue(row.accountBucket),
        paymentMode: PaymentMode.fromDbValue(row.paymentMode),
        amountPaise: row.amountPaise,
        linkedExpenseId: row.linkedExpenseId,
        reversesEntryId: row.reversesEntryId,
        clientRequestId: row.clientRequestId,
        referenceNo: row.referenceNo,
        reason: row.reason,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
