import 'dart:convert';

import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/backup/domain/entities/data_health_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Input descriptor for a single design colour evaluated by [DataHealthCalculator].
final class ColourReconciliationInput {
  const ColourReconciliationInput({
    required this.designColourId,
    required this.lotId,
    required this.lotNumber,
    required this.lotDesignId,
    required this.designName,
    required this.colourName,
    required this.unitPricePaise,
    required this.initialQuantity,
    required this.movements,
    required this.pendingInspectionQuantity,
    this.dispatchedOutQty = 0,
    this.buyerReturnedGoodQty = 0,
    this.buyerReturnedDamagedQty = 0,
  });

  final String designColourId;
  final String lotId;
  final String lotNumber;
  final String lotDesignId;
  final String designName;
  final String colourName;
  final int unitPricePaise;
  final int initialQuantity;
  final List<StockMovementEntity> movements;
  final int pendingInspectionQuantity;
  final int dispatchedOutQty;
  final int buyerReturnedGoodQty;
  final int buyerReturnedDamagedQty;
}

/// Pure Dart deterministic health & reconciliation calculator.
///
/// Zero Flutter, Drift, or platform IO dependencies so every check is
/// independently unit-testable per `AGENT_RULES.md`.
final class DataHealthCalculator {
  const DataHealthCalculator({StockCalculator? stockCalculator})
    : _stockCalculator = stockCalculator ?? const StockCalculator();

  final StockCalculator _stockCalculator;

  /// Verifies the golden stock reconciliation equation across all colours:
  /// `initial == available + withWorkers + pendingQc + damaged + lost + shortage + netDispatched`
  /// and verifies no stock bucket is negative.
  List<StockReconciliationIssue> evaluateStockReconciliation(
    List<ColourReconciliationInput> colours,
  ) {
    final issues = <StockReconciliationIssue>[];

    for (final c in colours) {
      final balance = _stockCalculator.calculateDesignColourBalance(
        designColourId: c.designColourId,
        lotId: c.lotId,
        lotNumber: c.lotNumber,
        lotDesignId: c.lotDesignId,
        designName: c.designName,
        colourName: c.colourName,
        unitPricePaise: c.unitPricePaise,
        initialQuantity: c.initialQuantity,
        allMovementsForColour: c.movements,
        pendingInspectionQuantity: c.pendingInspectionQuantity,
        dispatchedOutQty: c.dispatchedOutQty,
        buyerReturnedGoodQty: c.buyerReturnedGoodQty,
        buyerReturnedDamagedQty: c.buyerReturnedDamagedQty,
      );

      final reconciledTotal =
          balance.physicalAvailableInHouse +
          balance.totalPendingWithWorkers +
          balance.totalPendingInspection +
          balance.damagedBucket +
          balance.totalLost +
          balance.totalShortage +
          balance.netDispatchedQty;

      String? reason;
      if (balance.physicalAvailableInHouse < 0 ||
          balance.totalPendingWithWorkers < 0 ||
          balance.totalPendingInspection < 0 ||
          balance.damagedBucket < 0 ||
          balance.totalLost < 0 ||
          balance.totalShortage < 0 ||
          balance.netDispatchedQty < 0) {
        reason = 'NEGATIVE_BUCKET';
      } else if (reconciledTotal != c.initialQuantity) {
        reason = 'GOLDEN_EQUATION_MISMATCH';
      }

      if (reason != null) {
        issues.add(
          StockReconciliationIssue(
            lotNumber: c.lotNumber,
            designName: c.designName,
            colourName: c.colourName,
            designColourId: c.designColourId,
            initialQty: c.initialQuantity,
            reconciledTotalQty: reconciledTotal,
            availableGoodQty: balance.physicalAvailableInHouse,
            withWorkersQty: balance.totalPendingWithWorkers,
            pendingQcQty: balance.totalPendingInspection,
            damagedQty: balance.damagedBucket,
            lostQty: balance.totalLost,
            shortageQty: balance.totalShortage,
            reasonCode: reason,
          ),
        );
      }
    }

    return issues;
  }

  /// Evaluates orphan and missing media relative paths by comparing local files
  /// against active database attachment records.
  ({List<String> orphanPaths, List<String> missingPaths}) evaluateMediaParity({
    required Set<String> referencedRelativePaths,
    required Set<String> storedRelativePaths,
    required bool hasLocalMediaFilesystem,
  }) {
    if (!hasLocalMediaFilesystem) {
      return (orphanPaths: const [], missingPaths: const []);
    }
    final normalizedReferenced = referencedRelativePaths
        .map((p) => p.replaceAll('\\', '/').trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    final normalizedStored = storedRelativePaths
        .map((p) => p.replaceAll('\\', '/').trim())
        .where((p) => p.isNotEmpty)
        .toSet();

    final orphans = normalizedStored.difference(normalizedReferenced).toList()
      ..sort();
    final missing = normalizedReferenced.difference(normalizedStored).toList()
      ..sort();

    return (orphanPaths: orphans, missingPaths: missing);
  }

  /// Combines all diagnostic signals into a classified [DataHealthReport].
  DataHealthReport buildReport({
    required int checkedAtUtcMillis,
    required int schemaVersion,
    required bool sqliteIntegrityOk,
    required List<String> sqliteIntegrityMessages,
    required List<ForeignKeyViolation> foreignKeyViolations,
    required int totalColoursChecked,
    required List<StockReconciliationIssue> stockIssues,
    required List<LedgerParityIssue> ledgerIssues,
    required int syncOutboxPending,
    required int syncOutboxFailed,
    required int syncMediaPending,
    required int syncMediaFailed,
    required List<String> orphanMediaPaths,
    required List<String> missingMediaPaths,
    required int estimatedDbSizeBytes,
  }) {
    final hasCritical =
        !sqliteIntegrityOk ||
        foreignKeyViolations.isNotEmpty ||
        stockIssues.isNotEmpty ||
        ledgerIssues.isNotEmpty;
    final hasWarning =
        syncOutboxFailed > 0 ||
        syncMediaFailed > 0 ||
        orphanMediaPaths.isNotEmpty ||
        missingMediaPaths.isNotEmpty;

    final status = hasCritical
        ? DataHealthStatus.critical
        : hasWarning
        ? DataHealthStatus.warning
        : DataHealthStatus.healthy;

    return DataHealthReport(
      checkedAtUtcMillis: checkedAtUtcMillis,
      schemaVersion: schemaVersion,
      sqliteIntegrityOk: sqliteIntegrityOk,
      sqliteIntegrityMessages: sqliteIntegrityMessages,
      foreignKeyViolations: foreignKeyViolations,
      totalColoursChecked: totalColoursChecked,
      stockIssues: stockIssues,
      ledgerIssues: ledgerIssues,
      syncOutboxPending: syncOutboxPending,
      syncOutboxFailed: syncOutboxFailed,
      syncMediaPending: syncMediaPending,
      syncMediaFailed: syncMediaFailed,
      orphanMediaPaths: orphanMediaPaths,
      missingMediaPaths: missingMediaPaths,
      estimatedDbSizeBytes: estimatedDbSizeBytes,
      status: status,
    );
  }

  /// Produces a human-readable, shareable diagnostic export string (with JSON
  /// details) suitable for WhatsApp/email troubleshooting without exposing PII
  /// credentials.
  String formatDiagnosticExport(DataHealthReport report) {
    final checkedIst = IstDateTimeHelper.formatIstIsoDateTime(
      report.checkedAtUtcMillis,
    );
    final sizeKb = (report.estimatedDbSizeBytes / 1024).toStringAsFixed(1);
    final buffer = StringBuffer()
      ..writeln('StitchFlow Data Health Diagnostic Report')
      ..writeln('Checked At (IST): $checkedIst')
      ..writeln('Schema Version: v${report.schemaVersion}')
      ..writeln('Overall Status: ${report.status.name.toUpperCase()}')
      ..writeln('Database Size: $sizeKb KB')
      ..writeln(
        'SQLite Integrity: ${report.sqliteIntegrityOk ? 'OK' : 'FAILED'}',
      )
      ..writeln('Foreign Key Violations: ${report.foreignKeyViolations.length}')
      ..writeln(
        'Stock Reconciliation: ${report.totalColoursChecked - report.stockIssues.length}/${report.totalColoursChecked} OK (${report.stockIssues.length} issues)',
      )
      ..writeln('Ledger Parity Issues: ${report.ledgerIssues.length}')
      ..writeln(
        'Sync Queue: ${report.syncOutboxPending} pending, ${report.syncOutboxFailed} failed (Media: ${report.syncMediaPending} pending, ${report.syncMediaFailed} failed)',
      )
      ..writeln(
        'Media Parity: ${report.orphanMediaPaths.length} orphan, ${report.missingMediaPaths.length} missing',
      )
      ..writeln('')
      ..writeln('--- JSON Details ---')
      ..writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
    return buffer.toString();
  }
}
