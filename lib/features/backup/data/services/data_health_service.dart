import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/backup/domain/calculators/data_health_calculator.dart';
import 'package:business_manager/features/backup/domain/entities/data_health_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';

/// Offline-first, Web-safe Data Health & Reconciliation service.
///
/// Runs non-destructive diagnostics (`PRAGMA integrity_check`,
/// `PRAGMA foreign_key_check`, golden stock equation, ledger parity, sync queue
/// health, media parity) and exposes strictly safe, audited maintenance actions.
@lazySingleton
final class DataHealthService {
  DataHealthService(
    this._db,
    this._mediaStorage,
    this._idGenerator, {
    @ignoreParam DataHealthCalculator? calculator,
  }) : _calculator = calculator ?? const DataHealthCalculator();

  final AppDatabase _db;
  final MediaStorageService _mediaStorage;
  final IdGenerator _idGenerator;
  final DataHealthCalculator _calculator;

  Future<DataHealthReport> runFullDiagnostics() async {
    final now = IstDateTimeHelper.nowUtcMillis();

    // 1. SQLite integrity_check
    final integrityRows = await _db
        .customSelect('PRAGMA integrity_check;')
        .get();
    final integrityMessages = integrityRows
        .map((r) => r.data.values.first?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final sqliteIntegrityOk =
        integrityMessages.length == 1 &&
        integrityMessages.first.toLowerCase() == 'ok';

    // 2. SQLite foreign_key_check
    final fkRows = await _db.customSelect('PRAGMA foreign_key_check;').get();
    final fkViolations = fkRows
        .map(
          (r) => ForeignKeyViolation(
            table: r.data['table']?.toString() ?? '',
            rowId: r.data['rowid']?.toString() ?? '',
            parentTable: r.data['parent']?.toString() ?? '',
            foreignKeyIndex: (r.data['fkid'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();

    // 3. Cross-platform DB size estimate via PRAGMA page_count * page_size
    var estimatedDbSizeBytes = 0;
    try {
      final pageCountRow = await _db
          .customSelect('PRAGMA page_count;')
          .getSingle();
      final pageSizeRow = await _db
          .customSelect('PRAGMA page_size;')
          .getSingle();
      final pageCount = (pageCountRow.data.values.first as num?)?.toInt() ?? 0;
      final pageSize = (pageSizeRow.data.values.first as num?)?.toInt() ?? 4096;
      estimatedDbSizeBytes = pageCount * pageSize;
    } catch (_) {
      estimatedDbSizeBytes = 0;
    }

    // 4. Golden Stock Reconciliation across every design_colour
    final lots = await _db.lotDao.getActiveLots();
    final lotById = {for (final l in lots) l.id: l};
    final designs = await _db.lotDao.getAllActiveDesigns();
    final designById = {for (final d in designs) d.id: d};
    final colours = await _db.lotDao.getColoursForDesigns(
      designs.map((d) => d.id).toList(),
    );
    final allMovements = await _db.stockMovementDao.getAllMovements();

    final movementsByColour = <String, List<StockMovementEntity>>{};
    for (final m in allMovements) {
      movementsByColour
          .putIfAbsent(m.designColourId, () => <StockMovementEntity>[])
          .add(_mapMovement(m));
    }

    final pendingQcByColour = await _loadPendingQcByColour();
    final reconciliationInputs = <ColourReconciliationInput>[];
    for (final c in colours) {
      final design = designById[c.lotDesignId];
      final lot = design != null ? lotById[design.lotId] : null;
      reconciliationInputs.add(
        ColourReconciliationInput(
          designColourId: c.id,
          lotId: lot?.id ?? '',
          lotNumber: lot?.lotNumber ?? 'UNKNOWN',
          lotDesignId: c.lotDesignId,
          designName: design?.designName ?? 'UNKNOWN',
          colourName: c.colourName,
          unitPricePaise: c.unitPricePaise,
          initialQuantity: c.initialQuantity,
          movements: movementsByColour[c.id] ?? const [],
          pendingInspectionQuantity: pendingQcByColour[c.id] ?? 0,
        ),
      );
    }
    final stockIssues = _calculator.evaluateStockReconciliation(
      reconciliationInputs,
    );

    // 5. Ledger parity checks (unmigrated charges, reversed-issue active labour)
    final ledgerIssues = await _checkLedgerParity();

    // 6. Sync queue health
    final outboxPending = await _db.syncDao.getPendingOutboxCount();
    final outboxFailed = (await _db.syncDao.getFailedOutboxItems()).length;
    final mediaPending = await _db.syncDao.getPendingMediaCount();
    final mediaFailed = (await _db.syncDao.getFailedMediaItems()).length;

    // 7. Media file parity (native filesystem vs attachments table)
    final activeAttachments = await _db.attachmentAuditDao
        .getAllActiveAttachments();
    final referencedPaths = activeAttachments
        .map((a) => a.relativePath)
        .toSet();
    final storedPaths = (await _mediaStorage.listAllRelativePaths()).toSet();
    final mediaParity = _calculator.evaluateMediaParity(
      referencedRelativePaths: referencedPaths,
      storedRelativePaths: storedPaths,
      hasLocalMediaFilesystem: !kIsWeb,
    );

    return _calculator.buildReport(
      checkedAtUtcMillis: now,
      schemaVersion: _db.schemaVersion,
      sqliteIntegrityOk: sqliteIntegrityOk,
      sqliteIntegrityMessages: integrityMessages,
      foreignKeyViolations: fkViolations,
      totalColoursChecked: colours.length,
      stockIssues: stockIssues,
      ledgerIssues: ledgerIssues,
      syncOutboxPending: outboxPending,
      syncOutboxFailed: outboxFailed,
      syncMediaPending: mediaPending,
      syncMediaFailed: mediaFailed,
      orphanMediaPaths: mediaParity.orphanPaths,
      missingMediaPaths: mediaParity.missingPaths,
      estimatedDbSizeBytes: estimatedDbSizeBytes,
    );
  }

  /// Formats a shareable plain-text + JSON diagnostic bundle.
  String formatExportText(DataHealthReport report) =>
      _calculator.formatDiagnosticExport(report);

  /// Safe audited maintenance: flushes WAL into the main SQLite file.
  Future<void> runWalCheckpoint() async {
    await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    await _insertMaintenanceAudit(
      operationId: 'wal_checkpoint',
      reason: 'User-initiated WAL checkpoint from Data Health Center',
      details: const {'operation': 'wal_checkpoint_truncate'},
    );
  }

  /// Safe audited maintenance: deletes strictly unreferenced files inside the
  /// private flavor media root (never deletes active DB attachments).
  Future<int> cleanOrphanMediaFiles() async {
    if (kIsWeb) return 0;
    final activeAttachments = await _db.attachmentAuditDao
        .getAllActiveAttachments();
    final referenced = activeAttachments
        .map((a) => a.relativePath.replaceAll('\\', '/').trim())
        .toSet();
    final stored = (await _mediaStorage.listAllRelativePaths()).toSet();
    final orphans = stored.difference(referenced).toList()..sort();

    var deletedCount = 0;
    for (final path in orphans) {
      if (await _mediaStorage.deleteIfExists(path)) {
        deletedCount++;
      }
    }

    await _insertMaintenanceAudit(
      operationId: 'orphan_media_clean',
      reason: 'Cleaned unreferenced local media files from Data Health Center',
      details: {'deletedCount': deletedCount, 'paths': orphans},
    );
    return deletedCount;
  }

  /// Safe audited maintenance: resets failed outbox & media queue entries so
  /// the next sync cycle retries them immediately.
  Future<int> retryFailedSyncEntries() async {
    final failedOutbox = (await _db.syncDao.getFailedOutboxItems()).length;
    final failedMedia = (await _db.syncDao.getFailedMediaItems()).length;
    await _db.syncDao.resetFailedOutboxItems();
    await _db.syncDao.resetFailedMediaItems();
    final total = failedOutbox + failedMedia;
    await _insertMaintenanceAudit(
      operationId: 'sync_retry_reset',
      reason: 'Reset failed sync queue entries from Data Health Center',
      details: {'outboxReset': failedOutbox, 'mediaReset': failedMedia},
    );
    return total;
  }

  Future<Map<String, int>> _loadPendingQcByColour() async {
    final rows = await _db
        .customSelect(
          'SELECT r.design_colour_id AS colour_id, '
          'COALESCE(SUM(MAX(r.returned_quantity - COALESCE(('
          '  SELECT SUM(i.accepted_quantity + i.rejected_quantity) '
          '  FROM production_inspections i '
          '  WHERE i.production_return_id = r.id'
          '), 0), 0)), 0) AS pending_qc '
          'FROM production_returns r '
          'WHERE r.deleted_at IS NULL '
          'GROUP BY r.design_colour_id',
        )
        .get();
    return {
      for (final r in rows)
        r.read<String>('colour_id'): r.read<int>('pending_qc'),
    };
  }

  Future<List<LedgerParityIssue>> _checkLedgerParity() async {
    final issues = <LedgerParityIssue>[];

    // Check A: process_additional_charges without linked worker_ledger_adjustments
    final unlinkedCharges = await _db
        .customSelect(
          'SELECT id, job_process_id, amount_paise '
          'FROM process_additional_charges '
          'WHERE ledger_adjustment_id IS NULL',
        )
        .get();
    for (final r in unlinkedCharges) {
      issues.add(
        LedgerParityIssue(
          code: 'UNLINKED_PROCESS_CHARGE',
          entityId: r.read<String>('id'),
          details:
              'Process charge ${r.read<String>('id')} (${r.read<int>('amount_paise')} paise) has no linked worker_ledger_adjustment.',
        ),
      );
    }

    // Check B: active payable labour linked to a reversed stock movement
    final orphanLabour = await _db
        .customSelect(
          'SELECT l.id, l.stock_movement_id, l.amount_paise '
          'FROM labour_entries l '
          'WHERE l.reverses_labour_entry_id IS NULL '
          '  AND l.is_payable = 1 '
          '  AND NOT EXISTS ('
          '    SELECT 1 FROM labour_entries lr '
          '    WHERE lr.reverses_labour_entry_id = l.id'
          '  ) '
          '  AND EXISTS ('
          '    SELECT 1 FROM stock_movements rev '
          "    WHERE rev.movement_type = 'REVERSAL' "
          '      AND rev.reverses_movement_id = l.stock_movement_id'
          '  )',
        )
        .get();
    for (final r in orphanLabour) {
      issues.add(
        LedgerParityIssue(
          code: 'ACTIVE_LABOUR_ON_REVERSED_MOVEMENT',
          entityId: r.read<String>('id'),
          details:
              'Active labour entry ${r.read<String>('id')} references reversed movement ${r.read<String>('stock_movement_id')}.',
        ),
      );
    }

    return issues;
  }

  Future<void> _insertMaintenanceAudit({
    required String operationId,
    required String reason,
    required Map<String, Object?> details,
  }) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    await _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion.insert(
        id: _idGenerator.nextEntityId(),
        entityType: 'DATA_HEALTH',
        entityId: operationId,
        actionType: 'UPDATE',
        newValueJson: Value(jsonEncode(details)),
        reason: Value(reason),
        transactionAt: now,
        recordedAt: now,
      ),
    );
  }

  StockMovementEntity _mapMovement(StockMovementRow row) => StockMovementEntity(
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
}
