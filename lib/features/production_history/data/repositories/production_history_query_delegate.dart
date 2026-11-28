import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_dataset_loader.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';

/// Read-only query and drill-down delegate for [ProductionHistoryRepositoryImpl].
final class ProductionHistoryQueryDelegate {
  const ProductionHistoryQueryDelegate(this._db, this._calc);

  final AppDatabase _db;
  final ProductionHistoryCalculator _calc;

  Future<ProductionHistoryDashboardData> getDashboard({
    ProductionHistoryFilter filter = const ProductionHistoryFilter(),
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    return _calc.buildDashboard(data, filter: filter);
  }

  Future<LotCompleteHistory?> getLotCompleteHistory(String lotId) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    return _calc.buildLotCompleteHistory(lotId, data);
  }

  Future<List<LotTimelineEvent>> getLotTimeline(String lotId) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    return _calc.buildLotTimeline(lotId, data);
  }

  Future<WorkerCompleteProfile?> getWorkerCompleteProfile(
    String workerId, {
    ProductionHistoryFilter? filter,
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    return _calc.buildWorkerCompleteProfile(workerId, data, filter: filter);
  }

  Future<List<WorkerCompleteProfile>> getAllWorkerProfiles({
    ProductionHistoryFilter? filter,
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    final profiles = <WorkerCompleteProfile>[];
    for (final wId in data.workers.keys) {
      if (filter?.workerId != null && wId != filter!.workerId) continue;
      final profile = _calc.buildWorkerCompleteProfile(
        wId,
        data,
        filter: filter,
      );
      if (profile != null) {
        if (filter?.searchQuery != null &&
            filter!.searchQuery!.trim().isNotEmpty) {
          final q = filter.searchQuery!.trim().toLowerCase();
          final hay = '${profile.workerName} ${profile.phone ?? ''}'
              .toLowerCase();
          if (!hay.contains(q) && profile.lotHistory.isEmpty) continue;
        }
        profiles.add(profile);
      }
    }
    profiles.sort(
      (a, b) => b.financialSummary.outstandingPayablePaise.compareTo(
        a.financialSummary.outstandingPayablePaise,
      ),
    );
    return profiles;
  }

  Future<List<ProcessCompleteHistory>> getAllProcessHistories({
    ProductionHistoryFilter? filter,
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    return _calc.buildAllProcessHistories(data, filter: filter);
  }

  Future<ProcessCompleteHistory?> getProcessCompleteHistory(
    String processId, {
    ProductionHistoryFilter? filter,
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    final list = _calc.buildAllProcessHistories(
      data,
      filter: (filter ?? const ProductionHistoryFilter()).copyWith(
        processId: processId,
      ),
    );
    return list.isNotEmpty ? list.first : null;
  }

  Future<List<PendingReturnView>> getPendingReturns({
    String? lotId,
    String? workerId,
    String? processId,
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    return _calc.buildPendingReturns(
      data,
      lotId: lotId,
      workerId: workerId,
      processId: processId,
    );
  }

  Future<List<RejectionRecordView>> getRejectionRecords({
    String? lotId,
    String? workerId,
    String? processId,
    bool onlyOpen = false,
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);
    return _calc.buildRejectionViews(
      data,
      lotId: lotId,
      workerId: workerId,
      processId: processId,
      onlyOpen: onlyOpen,
    );
  }

  Future<ProductionTransactionDetail?> getTransactionDetail({
    required ProductionTransactionKind kind,
    required String id,
  }) async {
    final data = await ProductionHistoryDatasetLoader.loadDataset(_db);

    Future<List<ProductionAuditEntryView>> loadAudits(
      String entityType,
      String entityId,
    ) async {
      final rows = await _db.attachmentAuditDao.getAuditLogsForEntity(
        entityType,
        entityId,
      );
      return rows
          .map(
            (a) => ProductionAuditEntryView(
              id: a.id,
              actionType: a.actionType,
              actor: a.actor,
              reason: a.reason,
              recordedAt: a.recordedAt,
              newValueJson: a.newValueJson,
            ),
          )
          .toList();
    }

    switch (kind) {
      case ProductionTransactionKind.stockMovement:
        final movRow = await _db.stockMovementDao.findById(id);
        if (movRow == null) return null;
        final m = LedgerRowMappers.stockMovement(movRow);
        final links = <ProductionRelatedLink>[];
        if (m.parentIssueId != null) {
          links.add(
            ProductionRelatedLink(
              label: 'Parent Issue Assignment',
              code: 'parent_issue',
              kind: ProductionTransactionKind.stockMovement,
              id: m.parentIssueId!,
            ),
          );
        }
        final labRows = await _db.labourEntryDao.getEntriesForMovement(m.id);
        for (final l in labRows) {
          links.add(
            ProductionRelatedLink(
              label: 'Labour Entry (${l.basisType})',
              code: 'labour_entry',
              args: {'basis': l.basisType},
              kind: ProductionTransactionKind.labourEntry,
              id: l.id,
            ),
          );
        }
        return ProductionTransactionDetail(
          kind: kind,
          id: m.id,
          title: 'Stock Movement — ${m.movementType.dbValue}',
          statusLabel: m.movementType.dbValue,
          titleCode: 'stock_movement',
          statusCode: m.movementType.dbValue,
          traceArgs: {'movementType': m.movementType},
          transactionAt: m.transactionAt,
          recordedAt: m.recordedAt,
          actor: m.createdBy,
          lotId: m.lotId,
          lotNumber: data.lots[m.lotId]?.entity.lotNumber ?? m.lotId,
          designName: data.designs[m.lotDesignId]?.designName,
          colourName: data.colours[m.designColourId]?.colourName,
          processId: m.processId,
          processName: m.processId != null
              ? data.processes[m.processId!]?.name
              : null,
          workerId: m.memberId,
          workerName: m.memberId != null
              ? data.workers[m.memberId!]?.name
              : null,
          quantity: m.quantity,
          lockedRatePaise: m.appliedRatePaise,
          amountPaise: m.quantity * m.appliedRatePaise,
          reason: m.reason ?? m.overrideReason,
          notes: m.notes,
          parentIssueId: m.parentIssueId,
          relatedLinks: links,
          auditTrail: await loadAudits('stock_movements', m.id),
        );

      case ProductionTransactionKind.productionReturn:
        final retRow = await _db.productionTrackingDao.findReturnById(id);
        if (retRow == null) return null;
        final r = ProductionHistoryDatasetLoader.mapReturn(retRow);
        final insps = await _db.productionTrackingDao.getInspectionsForReturn(
          r.id,
        );
        final links = <ProductionRelatedLink>[
          ProductionRelatedLink(
            label: 'Parent Assignment Issue',
            code: 'parent_issue',
            kind: ProductionTransactionKind.stockMovement,
            id: r.parentIssueId,
          ),
          for (final i in insps)
            ProductionRelatedLink(
              label:
                  'Inspection (Acc ${i.acceptedQuantity}, Rej ${i.rejectedQuantity})',
              code: 'inspection',
              args: {'acc': i.acceptedQuantity, 'rej': i.rejectedQuantity},
              kind: ProductionTransactionKind.inspection,
              id: i.id,
            ),
        ];
        return ProductionTransactionDetail(
          kind: kind,
          id: r.id,
          title: 'Production Return Receipt',
          statusLabel: r.returnMode.dbValue,
          titleCode: 'production_return',
          statusCode: r.returnMode == ProductionReturnMode.pendingInspection
              ? 'pending_qc'
              : 'returned',
          transactionAt: r.transactionAt,
          recordedAt: r.recordedAt,
          actor: r.createdBy,
          lotId: r.lotId,
          lotNumber: data.lots[r.lotId]?.entity.lotNumber ?? r.lotId,
          designName: data.designs[r.lotDesignId]?.designName,
          colourName: data.colours[r.designColourId]?.colourName,
          processId: r.processId,
          processName: data.processes[r.processId]?.name,
          workerId: r.memberId,
          workerName: data.workers[r.memberId]?.name,
          quantity: r.returnedQuantity,
          notes: r.notes,
          parentIssueId: r.parentIssueId,
          relatedLinks: links,
          auditTrail: await loadAudits('production_returns', r.id),
        );

      case ProductionTransactionKind.inspection:
        final inspRow = await _db.productionTrackingDao.findInspectionById(id);
        if (inspRow == null) return null;
        final i = ProductionHistoryDatasetLoader.mapInspection(inspRow);
        final isReinsp =
            i.inspectionType == ProductionInspectionType.reinspection;
        final links = <ProductionRelatedLink>[
          ProductionRelatedLink(
            label: 'Parent Assignment Issue',
            code: 'parent_issue',
            kind: ProductionTransactionKind.stockMovement,
            id: i.parentIssueId,
          ),
          if (i.productionReturnId != null)
            ProductionRelatedLink(
              label: 'Production Return Receipt',
              code: 'production_return',
              kind: ProductionTransactionKind.productionReturn,
              id: i.productionReturnId!,
            ),
          if (i.linkedLabourEntryId != null)
            ProductionRelatedLink(
              label: 'Generated Worker Earning',
              code: 'worker_earning',
              kind: ProductionTransactionKind.labourEntry,
              id: i.linkedLabourEntryId!,
            ),
          if (i.rejectionRecordId != null)
            ProductionRelatedLink(
              label: 'Original Rejection Record',
              code: 'original_rejection',
              kind: ProductionTransactionKind.rejection,
              id: i.rejectionRecordId!,
            ),
        ];
        return ProductionTransactionDetail(
          kind: kind,
          id: i.id,
          title: isReinsp
              ? 'Repair Re-Inspection & Approval'
              : 'Quality Inspection & Approval',
          statusLabel: i.inspectionType.dbValue,
          titleCode: isReinsp ? 'reinspection' : 'inspection',
          statusCode: isReinsp ? 'reapproved' : 'inspected',
          transactionAt: i.transactionAt,
          recordedAt: i.recordedAt,
          actor: i.inspectedBy,
          approvedBy: i.approvedBy,
          authorizedViaPin: i.authorizedViaPin,
          lotId: i.lotId,
          lotNumber: data.lots[i.lotId]?.entity.lotNumber ?? i.lotId,
          designName: data.designs[i.lotDesignId]?.designName,
          colourName: data.colours[i.designColourId]?.colourName,
          processId: i.processId,
          processName: data.processes[i.processId]?.name,
          workerId: i.memberId,
          workerName: data.workers[i.memberId]?.name,
          quantity: i.totalInspectedQuantity,
          acceptedQuantity: i.acceptedQuantity,
          rejectedQuantity: i.rejectedQuantity,
          lockedRatePaise: i.lockedRatePaise,
          amountPaise: i.earnedAmountPaise,
          reason: i.rejectionReason,
          notes: i.notes,
          parentIssueId: i.parentIssueId,
          relatedLinks: links,
          auditTrail: await loadAudits('production_inspections', i.id),
        );

      case ProductionTransactionKind.rejection:
        final rejRow = await _db.productionTrackingDao.findRejectionById(id);
        if (rejRow == null) return null;
        final r = ProductionHistoryDatasetLoader.mapRejection(rejRow);
        final repairs = await _db.productionTrackingDao.getRepairsForRejection(
          r.id,
        );
        return ProductionTransactionDetail(
          kind: kind,
          id: r.id,
          title: 'Rejection / Defect Record',
          statusLabel: r.status.dbValue,
          titleCode: 'rejection',
          statusCode: r.status.dbValue,
          transactionAt: r.inspectedAt,
          recordedAt: r.createdAt,
          actor: r.recordedBy,
          lotId: r.lotId,
          lotNumber: data.lots[r.lotId]?.entity.lotNumber ?? r.lotId,
          designName: data.designs[r.lotDesignId]?.designName,
          colourName: data.colours[r.designColourId]?.colourName,
          processId: r.processId,
          processName: data.processes[r.processId]?.name,
          workerId: r.memberId,
          workerName: data.workers[r.memberId]?.name,
          rejectedQuantity: r.rejectedQuantity,
          quantity: r.rejectedQuantity,
          amountPaise: 0,
          reason: r.rejectionReason,
          notes: r.notes,
          parentIssueId: r.parentIssueId,
          relatedLinks: [
            ProductionRelatedLink(
              label: 'Inspection Event',
              code: 'inspection_event',
              kind: ProductionTransactionKind.inspection,
              id: r.inspectionId,
            ),
            for (final rep in repairs)
              ProductionRelatedLink(
                label: 'Repair (${rep.repairedQuantity} pcs)',
                code: 'repair',
                args: {'qty': rep.repairedQuantity},
                kind: ProductionTransactionKind.repair,
                id: rep.id,
              ),
          ],
          auditTrail: await loadAudits(
            'production_inspections',
            r.inspectionId,
          ),
        );

      case ProductionTransactionKind.repair:
        final repRow = await _db.productionTrackingDao.findRepairById(id);
        if (repRow == null) return null;
        final rep = ProductionHistoryDatasetLoader.mapRepair(repRow);
        final insps = await _db.productionTrackingDao.getInspectionsForRepair(
          rep.id,
        );
        return ProductionTransactionDetail(
          kind: kind,
          id: rep.id,
          title: 'Rejection Repair Operation',
          statusLabel: '${rep.repairSource.dbValue} • ${rep.status.dbValue}',
          titleCode: 'repair',
          statusCode: rep.status.dbValue,
          transactionAt: rep.transactionAt,
          recordedAt: rep.recordedAt,
          actor: rep.repairedBy,
          lotId: rep.lotId,
          lotNumber: data.lots[rep.lotId]?.entity.lotNumber ?? rep.lotId,
          colourName: data.colours[rep.designColourId]?.colourName,
          processId: rep.processId,
          processName: data.processes[rep.processId]?.name,
          workerId: rep.memberId,
          workerName: data.workers[rep.memberId]?.name,
          quantity: rep.repairedQuantity,
          notes: rep.notes,
          relatedLinks: [
            ProductionRelatedLink(
              label: 'Original Rejection Record',
              code: 'original_rejection',
              kind: ProductionTransactionKind.rejection,
              id: rep.rejectionRecordId,
            ),
            for (final ins in insps)
              ProductionRelatedLink(
                label: 'Re-Inspection (Acc ${ins.acceptedQuantity})',
                code: 'reinspection',
                args: {'acc': ins.acceptedQuantity},
                kind: ProductionTransactionKind.inspection,
                id: ins.id,
              ),
          ],
          auditTrail: await loadAudits('rejection_repairs', rep.id),
        );

      case ProductionTransactionKind.handover:
        final hoRow = await _db.jobProcessDao.findHandoverById(id);
        if (hoRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: hoRow.id,
          title: 'Process Handover — ${hoRow.handoverType}',
          statusLabel: hoRow.status,
          titleCode: 'handover',
          statusCode: hoRow.status,
          traceArgs: {'handoverType': hoRow.handoverType},
          transactionAt: hoRow.transactionAt,
          recordedAt: hoRow.recordedAt,
          actor: hoRow.createdBy,
          lotId: hoRow.lotId,
          lotNumber: data.lots[hoRow.lotId]?.entity.lotNumber ?? hoRow.lotId,
          designName: data.designs[hoRow.lotDesignId]?.designName,
          colourName: data.colours[hoRow.designColourId]?.colourName,
          processId: hoRow.processId,
          processName: data.processes[hoRow.processId]?.name,
          workerId: hoRow.toMemberId ?? hoRow.fromMemberId,
          workerName: (hoRow.toMemberId ?? hoRow.fromMemberId) != null
              ? data.workers[(hoRow.toMemberId ?? hoRow.fromMemberId)!]?.name
              : null,
          quantity: hoRow.quantityDispatched,
          referenceNo: hoRow.transferReference,
          notes: hoRow.notes,
          auditTrail: await loadAudits('PROCESS_HANDOVER', hoRow.id),
        );

      case ProductionTransactionKind.labourEntry:
        final labRow = await _db.labourEntryDao.findById(id);
        if (labRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: labRow.id,
          title: 'Worker Labour Earning (${labRow.basisType})',
          statusLabel: labRow.isPayable == 1 ? 'PAYABLE' : 'INFORMATIONAL',
          titleCode: 'labour_entry',
          statusCode: labRow.isPayable == 1 ? 'payable' : 'informational',
          traceArgs: {'basis': labRow.basisType},
          transactionAt: labRow.transactionAt,
          recordedAt: labRow.recordedAt,
          lotId: labRow.lotId,
          lotNumber: data.lots[labRow.lotId]?.entity.lotNumber ?? labRow.lotId,
          processId: labRow.processId,
          processName: data.processes[labRow.processId]?.name,
          workerId: labRow.memberId,
          workerName: data.workers[labRow.memberId]?.name,
          quantity: labRow.quantity,
          lockedRatePaise: labRow.ratePaise,
          amountPaise: labRow.amountPaise,
          relatedLinks: [
            ProductionRelatedLink(
              label: 'Linked Stock Movement',
              code: 'linked_movement',
              kind: ProductionTransactionKind.stockMovement,
              id: labRow.stockMovementId,
            ),
          ],
          auditTrail: await loadAudits(
            'stock_movements',
            labRow.stockMovementId,
          ),
        );

      case ProductionTransactionKind.payment:
        final payRow = await _db.paymentDao.findById(id);
        if (payRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: payRow.id,
          title: 'Worker Payment — ${payRow.paymentType}',
          statusLabel: payRow.paymentMode,
          titleCode: 'payment',
          statusCode: payRow.paymentMode,
          traceArgs: {'paymentType': payRow.paymentType},
          transactionAt: payRow.transactionAt,
          recordedAt: payRow.recordedAt,
          actor: payRow.createdBy,
          workerId: payRow.memberId,
          workerName: data.workers[payRow.memberId]?.name,
          amountPaise: payRow.amountPaise,
          referenceNo: payRow.referenceNo,
          reason: payRow.reason,
          notes: payRow.notes,
          auditTrail: await loadAudits('payments', payRow.id),
        );

      case ProductionTransactionKind.adjustment:
        final adjRow = await _db.workerAdjustmentDao.findById(id);
        if (adjRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: adjRow.id,
          title: 'Worker Ledger Adjustment — ${adjRow.adjustmentType}',
          statusLabel: adjRow.adjustmentType,
          titleCode: 'adjustment',
          statusCode: adjRow.adjustmentType,
          traceArgs: {'adjustmentType': adjRow.adjustmentType},
          transactionAt: adjRow.transactionAt,
          recordedAt: adjRow.recordedAt,
          actor: adjRow.createdBy,
          workerId: adjRow.memberId,
          workerName: data.workers[adjRow.memberId]?.name,
          amountPaise: adjRow.amountPaise,
          reason: adjRow.reason,
          notes: adjRow.notes,
          auditTrail: await loadAudits('worker_ledger_adjustments', adjRow.id),
        );
    }
  }

  Future<ProductionHistoryFilterOptions> getFilterOptions() async {
    final allLots = await _db.select(_db.lots).get();
    final allWorkers = await _db.select(_db.members).get();
    final allProcs = await _db.select(_db.processes).get();
    final allDesigns = await _db.select(_db.lotDesigns).get();
    final allColours = await _db.select(_db.designColours).get();

    final designNames = <String>{};
    for (final d in allDesigns) {
      if (d.designName.trim().isNotEmpty &&
          d.designName != kColourOnlyDesignSentinel) {
        designNames.add(d.designName.trim());
      }
    }
    final colourNames = <String>{};
    for (final c in allColours) {
      if (c.colourName.trim().isNotEmpty) {
        colourNames.add(c.colourName.trim());
      }
    }

    return ProductionHistoryFilterOptions(
      lots:
          allLots
              .map(
                (l) => HistoryFilterOption(
                  id: l.id,
                  label: l.lotNumber,
                  isActive: l.deletedAt == null && l.status != 'ARCHIVED',
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      workers:
          allWorkers
              .map(
                (w) => HistoryFilterOption(
                  id: w.id,
                  label: w.name,
                  isActive: w.isActive == 1 && w.deletedAt == null,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      processes:
          allProcs
              .map(
                (p) => HistoryFilterOption(
                  id: p.id,
                  label: p.name,
                  isActive: p.isActive == 1 && p.deletedAt == null,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      designNames: designNames.toList()..sort(),
      colourNames: colourNames.toList()..sort(),
    );
  }
}
