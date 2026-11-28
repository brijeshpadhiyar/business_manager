/// Metadata for a single synced StitchFlow table.
final class SyncTableSpec {
  const SyncTableSpec({
    required this.tableName,
    required this.appendOnly,
    this.selfReferenceColumns = const [],
  });

  final String tableName;
  final bool appendOnly;
  final List<String> selfReferenceColumns;
}

/// Pure Dart registry of all 30 synced tables in strict Foreign-Key topological
/// order, with self-reference sorting and exponential backoff math.
abstract final class SyncTableRegistry {
  static const List<SyncTableSpec> specs = [
    SyncTableSpec(tableName: 'attachments', appendOnly: false),
    SyncTableSpec(tableName: 'business_profile', appendOnly: false),
    SyncTableSpec(tableName: 'colour_master', appendOnly: false),
    SyncTableSpec(tableName: 'processes', appendOnly: false),
    SyncTableSpec(tableName: 'members', appendOnly: false),
    SyncTableSpec(tableName: 'member_processes', appendOnly: false),
    SyncTableSpec(tableName: 'member_process_rates', appendOnly: false),
    SyncTableSpec(tableName: 'lots', appendOnly: false),
    SyncTableSpec(tableName: 'lot_designs', appendOnly: false),
    SyncTableSpec(tableName: 'design_colours', appendOnly: false),
    SyncTableSpec(
      tableName: 'stock_movements',
      appendOnly: true,
      selfReferenceColumns: ['parent_issue_id', 'reverses_movement_id'],
    ),
    SyncTableSpec(
      tableName: 'job_processes',
      appendOnly: false,
      selfReferenceColumns: ['source_job_process_id'],
    ),
    SyncTableSpec(tableName: 'process_handovers', appendOnly: true),
    SyncTableSpec(tableName: 'process_additional_charges', appendOnly: true),
    SyncTableSpec(tableName: 'process_rate_history', appendOnly: true),
    SyncTableSpec(
      tableName: 'labour_entries',
      appendOnly: true,
      selfReferenceColumns: ['reverses_labour_entry_id'],
    ),
    SyncTableSpec(
      tableName: 'payments',
      appendOnly: true,
      selfReferenceColumns: ['reverses_payment_id'],
    ),
    SyncTableSpec(
      tableName: 'worker_ledger_adjustments',
      appendOnly: true,
      selfReferenceColumns: ['reverses_adjustment_id'],
    ),
    SyncTableSpec(tableName: 'production_returns', appendOnly: true),
    SyncTableSpec(tableName: 'production_inspections', appendOnly: true),
    SyncTableSpec(tableName: 'rejection_records', appendOnly: false),
    SyncTableSpec(tableName: 'rejection_repairs', appendOnly: false),
    SyncTableSpec(tableName: 'parties', appendOnly: false),
    SyncTableSpec(
      tableName: 'dispatch_challans',
      appendOnly: true,
      selfReferenceColumns: ['reverses_challan_id'],
    ),
    SyncTableSpec(tableName: 'dispatch_items', appendOnly: true),
    SyncTableSpec(
      tableName: 'buyer_returns',
      appendOnly: true,
      selfReferenceColumns: ['reverses_return_id'],
    ),
    SyncTableSpec(tableName: 'buyer_return_items', appendOnly: true),
    SyncTableSpec(
      tableName: 'party_payments',
      appendOnly: true,
      selfReferenceColumns: ['reverses_payment_id'],
    ),
    SyncTableSpec(
      tableName: 'lot_direct_costs',
      appendOnly: true,
      selfReferenceColumns: ['reverses_cost_id'],
    ),
    SyncTableSpec(
      tableName: 'workshop_expenses',
      appendOnly: true,
      selfReferenceColumns: ['reverses_expense_id'],
    ),
    SyncTableSpec(
      tableName: 'cashbook_entries',
      appendOnly: true,
      selfReferenceColumns: ['reverses_entry_id'],
    ),
    SyncTableSpec(tableName: 'audit_logs', appendOnly: true),
  ];

  /// All 32 synced domain tables in strict Foreign-Key topological push order.
  static const List<String> syncedTablesInPushOrder = [
    'attachments',
    'business_profile',
    'colour_master',
    'processes',
    'members',
    'member_processes',
    'member_process_rates',
    'lots',
    'lot_designs',
    'design_colours',
    'stock_movements',
    'job_processes',
    'process_handovers',
    'process_additional_charges',
    'process_rate_history',
    'labour_entries',
    'payments',
    'worker_ledger_adjustments',
    'production_returns',
    'production_inspections',
    'rejection_records',
    'rejection_repairs',
    'parties',
    'dispatch_challans',
    'dispatch_items',
    'buyer_returns',
    'buyer_return_items',
    'party_payments',
    'lot_direct_costs',
    'workshop_expenses',
    'cashbook_entries',
    'audit_logs',
  ];

  static final Map<String, SyncTableSpec> _byName = {
    for (final s in specs) s.tableName: s,
  };

  static final Map<String, int> _orderIndex = {
    for (var i = 0; i < syncedTablesInPushOrder.length; i++)
      syncedTablesInPushOrder[i]: i,
  };

  static SyncTableSpec? specFor(String tableName) => _byName[tableName];

  static int orderOf(String tableName) => _orderIndex[tableName] ?? 999;

  static bool isAppendOnly(String tableName) =>
      _byName[tableName]?.appendOnly ?? false;

  /// Topologically sorts rows of a self-referencing table so parent rows
  /// (e.g. `ISSUE` before `RETURN_GOOD` or `REVERSAL`) are always pushed or
  /// applied before their children.
  static List<Map<String, Object?>> sortSelfReferencingRows(
    String tableName,
    List<Map<String, Object?>> rows,
  ) {
    final spec = _byName[tableName];
    if (spec == null || spec.selfReferenceColumns.isEmpty || rows.length <= 1) {
      return rows;
    }

    final byId = <String, Map<String, Object?>>{};
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id != null) byId[id] = row;
    }

    final visited = <String>{};
    final visiting = <String>{};
    final sorted = <Map<String, Object?>>[];

    void visit(Map<String, Object?> row) {
      final id = row['id']?.toString();
      if (id == null || visited.contains(id) || visiting.contains(id)) return;
      visiting.add(id);
      for (final refCol in spec.selfReferenceColumns) {
        final parentId = row[refCol]?.toString();
        if (parentId != null && parentId != id && byId.containsKey(parentId)) {
          visit(byId[parentId]!);
        }
      }
      visiting.remove(id);
      visited.add(id);
      sorted.add(row);
    }

    for (final row in rows) {
      visit(row);
    }
    return sorted;
  }

  /// Deterministic exponential backoff schedule: 5s -> 15s -> 60s -> 300s (max).
  static Duration backoffForRetry(int retryCount) {
    return switch (retryCount) {
      <= 1 => const Duration(seconds: 5),
      2 => const Duration(seconds: 15),
      3 => const Duration(seconds: 60),
      _ => const Duration(minutes: 5),
    };
  }
}
