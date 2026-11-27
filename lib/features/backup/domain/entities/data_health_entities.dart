/// Overall health classification produced by [DataHealthCalculator].
enum DataHealthStatus { healthy, warning, critical }

/// Single SQLite `PRAGMA foreign_key_check` violation row.
final class ForeignKeyViolation {
  const ForeignKeyViolation({
    required this.table,
    required this.rowId,
    required this.parentTable,
    required this.foreignKeyIndex,
  });

  final String table;
  final String rowId;
  final String parentTable;
  final int foreignKeyIndex;

  Map<String, Object?> toJson() => {
    'table': table,
    'rowId': rowId,
    'parentTable': parentTable,
    'foreignKeyIndex': foreignKeyIndex,
  };
}

/// Discrepancy detected by the golden stock reconciliation equation:
/// `initial == available + withWorkers + pendingQc + damaged + lost + shortage`
/// or negative stock buckets.
final class StockReconciliationIssue {
  const StockReconciliationIssue({
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    required this.designColourId,
    required this.initialQty,
    required this.reconciledTotalQty,
    required this.availableGoodQty,
    required this.withWorkersQty,
    required this.pendingQcQty,
    required this.damagedQty,
    required this.lostQty,
    required this.shortageQty,
    required this.reasonCode,
  });

  final String lotNumber;
  final String designName;
  final String colourName;
  final String designColourId;
  final int initialQty;
  final int reconciledTotalQty;
  final int availableGoodQty;
  final int withWorkersQty;
  final int pendingQcQty;
  final int damagedQty;
  final int lostQty;
  final int shortageQty;
  final String reasonCode;

  int get delta => reconciledTotalQty - initialQty;

  Map<String, Object?> toJson() => {
    'lotNumber': lotNumber,
    'designName': designName,
    'colourName': colourName,
    'designColourId': designColourId,
    'initialQty': initialQty,
    'reconciledTotalQty': reconciledTotalQty,
    'delta': delta,
    'availableGoodQty': availableGoodQty,
    'withWorkersQty': withWorkersQty,
    'pendingQcQty': pendingQcQty,
    'damagedQty': damagedQty,
    'lostQty': lostQty,
    'shortageQty': shortageQty,
    'reasonCode': reasonCode,
  };
}

/// Worker ledger or charge-unification discrepancy.
final class LedgerParityIssue {
  const LedgerParityIssue({
    required this.code,
    required this.entityId,
    required this.details,
  });

  final String code;
  final String entityId;
  final String details;

  Map<String, Object?> toJson() => {
    'code': code,
    'entityId': entityId,
    'details': details,
  };
}

/// Complete, exportable snapshot of local StitchFlow data health.
final class DataHealthReport {
  const DataHealthReport({
    required this.checkedAtUtcMillis,
    required this.schemaVersion,
    required this.sqliteIntegrityOk,
    required this.sqliteIntegrityMessages,
    required this.foreignKeyViolations,
    required this.totalColoursChecked,
    required this.stockIssues,
    required this.ledgerIssues,
    required this.syncOutboxPending,
    required this.syncOutboxFailed,
    required this.syncMediaPending,
    required this.syncMediaFailed,
    required this.orphanMediaPaths,
    required this.missingMediaPaths,
    required this.estimatedDbSizeBytes,
    required this.status,
  });

  final int checkedAtUtcMillis;
  final int schemaVersion;
  final bool sqliteIntegrityOk;
  final List<String> sqliteIntegrityMessages;
  final List<ForeignKeyViolation> foreignKeyViolations;
  final int totalColoursChecked;
  final List<StockReconciliationIssue> stockIssues;
  final List<LedgerParityIssue> ledgerIssues;
  final int syncOutboxPending;
  final int syncOutboxFailed;
  final int syncMediaPending;
  final int syncMediaFailed;
  final List<String> orphanMediaPaths;
  final List<String> missingMediaPaths;
  final int estimatedDbSizeBytes;
  final DataHealthStatus status;

  int get totalCriticalCount =>
      (sqliteIntegrityOk ? 0 : 1) +
      foreignKeyViolations.length +
      stockIssues.length +
      ledgerIssues.length;

  int get totalWarningCount =>
      syncOutboxFailed +
      syncMediaFailed +
      orphanMediaPaths.length +
      missingMediaPaths.length;

  Map<String, Object?> toJson() => {
    'checkedAtUtcMillis': checkedAtUtcMillis,
    'schemaVersion': schemaVersion,
    'status': status.name,
    'sqliteIntegrityOk': sqliteIntegrityOk,
    'sqliteIntegrityMessages': sqliteIntegrityMessages,
    'foreignKeyViolations': foreignKeyViolations
        .map((e) => e.toJson())
        .toList(),
    'totalColoursChecked': totalColoursChecked,
    'stockIssues': stockIssues.map((e) => e.toJson()).toList(),
    'ledgerIssues': ledgerIssues.map((e) => e.toJson()).toList(),
    'syncOutboxPending': syncOutboxPending,
    'syncOutboxFailed': syncOutboxFailed,
    'syncMediaPending': syncMediaPending,
    'syncMediaFailed': syncMediaFailed,
    'orphanMediaPaths': orphanMediaPaths,
    'missingMediaPaths': missingMediaPaths,
    'estimatedDbSizeBytes': estimatedDbSizeBytes,
  };
}
