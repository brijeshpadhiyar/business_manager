import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/process_routing/domain/calculators/job_process_progress_calculator.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_routing_validator.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:drift/drift.dart';

/// Shared pricing, rate-lock, stock-issue, FIFO-settlement, and audit helpers
/// for process routing operations.
final class ProcessRoutingSupport {
  const ProcessRoutingSupport(this._db, this._stockRepo, this._idGenerator);

  final AppDatabase _db;
  final StockMovementRepository _stockRepo;
  final IdGenerator _idGenerator;

  static const ProcessRoutingValidator validator = ProcessRoutingValidator();
  static const ProcessPricingCalculator pricingCalc =
      ProcessPricingCalculator();
  static const JobProcessProgressCalculator progressCalc =
      JobProcessProgressCalculator();

  Never throwValidation(String code) =>
      throw DomainValidationException(code, code);

  Future<void> ensureMemberProcessLink({
    required String memberId,
    required String processId,
    required int now,
  }) async {
    final existing = await _db.processMemberDao.findMemberProcessLink(
      memberId,
      processId,
    );
    if (existing == null) {
      await _db.processMemberDao.insertMemberProcess(
        MemberProcessesCompanion.insert(
          id: _idGenerator.nextEntityId(),
          memberId: memberId,
          processId: processId,
          isActive: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else if (existing.isActive == 0) {
      await _db.processMemberDao.updateMemberProcessById(
        existing.id,
        MemberProcessesCompanion(
          isActive: const Value(1),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Resolves default rate using strict precedence:
  /// Worker-specific historical rate -> Process default rate -> 0.
  Future<
    ({
      int defaultRatePaise,
      int agreedRatePaise,
      String pricingUnit,
      int payableAmountPaise,
      int perPieceRatePaise,
      bool isOverridden,
      String? overrideReason,
    })
  >
  resolveAssignmentPricing({
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    int? requestedAgreedRatePaise,
    String? requestedPricingUnit,
    String? requestedOverrideReason,
  }) async {
    final procRow = await _db.processMemberDao.findProcessById(processId);
    if (procRow == null) throwValidation('process_not_found');

    var defaultRate = procRow.defaultRatePaise;
    var defaultUnit = procRow.defaultPricingUnit;

    final histRate = await _stockRepo.previewRate(
      workerId: workerId,
      processId: processId,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    if (histRate is RateResolutionFound) {
      defaultRate = histRate.rate.ratePaise;
      defaultUnit = 'PER_PIECE';
    }

    final agreedRate = requestedAgreedRatePaise ?? defaultRate;
    if (agreedRate < 0) throwValidation('invalid_rate');

    final unit =
        (requestedPricingUnit != null && requestedPricingUnit.trim().isNotEmpty)
        ? requestedPricingUnit.trim().toUpperCase()
        : defaultUnit;

    final isOverridden = agreedRate != defaultRate;
    final trimmedReason = requestedOverrideReason?.trim();
    if (isOverridden && (trimmedReason == null || trimmedReason.isEmpty)) {
      throwValidation('rate_override_reason_required');
    }

    final payable = pricingCalc.calculateBaseAmountPaise(
      quantity: quantity,
      ratePaise: agreedRate,
      pricingUnit: unit,
    );
    final perPiece = pricingCalc.effectivePerPieceRatePaise(
      quantity: quantity,
      ratePaise: agreedRate,
      pricingUnit: unit,
    );

    return (
      defaultRatePaise: defaultRate,
      agreedRatePaise: agreedRate,
      pricingUnit: unit,
      payableAmountPaise: payable,
      perPieceRatePaise: perPiece,
      isOverridden: isOverridden,
      overrideReason: isOverridden ? trimmedReason : null,
    );
  }

  Future<StockMovementEntity> issueStockWithResolvedRate({
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    required int effectivePerPieceRatePaise,
    required String? overrideReason,
    required String? notes,
    String? jobProcessId,
    required String? clientRequestId,
  }) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    await ensureMemberProcessLink(
      memberId: workerId,
      processId: processId,
      now: now,
    );

    final rateResult = await _stockRepo.previewRate(
      workerId: workerId,
      processId: processId,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    final matchesResolved = switch (rateResult) {
      RateResolutionFound(:final rate) =>
        rate.ratePaise == effectivePerPieceRatePaise,
      RateResolutionProcessDefault(:final ratePaise) =>
        ratePaise == effectivePerPieceRatePaise,
      _ => false,
    };

    return _stockRepo.issueStock(
      designColourId: designColourId,
      processId: processId,
      workerId: workerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      notes: notes,
      allowRateOverride: !matchesResolved,
      overrideRatePaise: matchesResolved ? null : effectivePerPieceRatePaise,
      overrideReason: matchesResolved
          ? null
          : (overrideReason ?? 'Dynamic assignment rate'),
      jobProcessId: jobProcessId,
      clientRequestId: clientRequestId,
    );
  }

  /// Splits a settlement over every open ISSUE of the operation (oldest first).
  Future<List<SettlementBatchResult>> settleFifo({
    required JobProcessProgress progress,
    required int goodQuantity,
    required int damagedQuantity,
    required int transactionAtUtcMillis,
    required String? reason,
    required String notes,
    required String? requestIdPrefix,
  }) async {
    final parts = progressCalc.allocateFifo(
      quantity: goodQuantity + damagedQuantity,
      openIssueIds: progress.openIssueIds,
      withWorkerByIssue: progress.withWorkerByIssue,
    );
    final allocated = parts.fold<int>(0, (s, p) => s + p.quantity);
    if (allocated < goodQuantity + damagedQuantity) {
      throwValidation('exceeds_pending_quantity');
    }
    var goodLeft = goodQuantity;
    final results = <SettlementBatchResult>[];
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final good = goodLeft < part.quantity ? goodLeft : part.quantity;
      goodLeft -= good;
      results.add(
        await _stockRepo.recordSettlement(
          parentIssueId: part.issueId,
          goodQuantity: good,
          damagedQuantity: part.quantity - good,
          lostQuantity: 0,
          shortageQuantity: 0,
          transactionAtUtcMillis: transactionAtUtcMillis,
          reason: reason,
          notes: notes,
          clientRequestId: requestIdPrefix == null
              ? null
              : (i == 0 ? requestIdPrefix : '${requestIdPrefix}_$i'),
        ),
      );
    }
    return results;
  }

  Future<void> writeAudit({
    required String entityType,
    required String entityId,
    required String actionType,
    required String actor,
    required Map<String, Object?> payload,
    required int transactionAt,
    required int now,
    String? reason,
  }) {
    return _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion.insert(
        id: _idGenerator.nextEntityId(),
        entityType: entityType,
        entityId: entityId,
        actionType: actionType,
        actor: Value(actor),
        newValueJson: Value(jsonEncode(payload)),
        reason: Value(reason),
        transactionAt: transactionAt,
        recordedAt: now,
      ),
    );
  }
}
