/// SQL statements for all documented partial unique indexes, composite indexes,
/// reversal uniqueness guards, and labour idempotency constraints
/// (`docs/07_database_schema.md` & `docs/24_FINAL_TECHNICAL_SAFEGUARDS.md`).
abstract final class SchemaIndexes {
  static const List<String> v1IndexStatements = [
    // Lots, designs, colours
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_lots_number_active '
        'ON lots(lot_number) WHERE deleted_at IS NULL;',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_lot_designs_unique '
        'ON lot_designs(lot_id, lower(design_name)) WHERE deleted_at IS NULL;',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_design_colours_unique '
        'ON design_colours(lot_design_id, lower(colour_name)) '
        'WHERE deleted_at IS NULL;',

    // Processes, members, rates
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_processes_name_active '
        'ON processes(lower(name)) WHERE deleted_at IS NULL;',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_member_processes_pair '
        'ON member_processes(member_id, process_id);',
    'CREATE INDEX IF NOT EXISTS idx_rates_lookup '
        'ON member_process_rates(member_id, process_id, effective_from, effective_to) '
        'WHERE deleted_at IS NULL;',

    // Stock movements (lookup + single reversal + idempotency)
    'CREATE INDEX IF NOT EXISTS idx_sm_design_colour '
        'ON stock_movements(design_colour_id, movement_type);',
    'CREATE INDEX IF NOT EXISTS idx_sm_parent_issue '
        'ON stock_movements(parent_issue_id);',
    'CREATE INDEX IF NOT EXISTS idx_sm_member_tx '
        'ON stock_movements(member_id, transaction_at DESC);',
    'CREATE INDEX IF NOT EXISTS idx_sm_process_tx '
        'ON stock_movements(process_id, transaction_at DESC);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_sm_single_reversal '
        'ON stock_movements(reverses_movement_id) '
        'WHERE reverses_movement_id IS NOT NULL;',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_sm_client_request_id '
        'ON stock_movements(client_request_id) '
        'WHERE client_request_id IS NOT NULL;',

    // Labour entries (lookup + movement/basis idempotency + single reversal)
    'CREATE INDEX IF NOT EXISTS idx_labour_member_payable '
        'ON labour_entries(member_id, is_payable, transaction_at DESC);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_labour_movement_basis_unique '
        'ON labour_entries(stock_movement_id, basis_type);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_labour_single_reversal '
        'ON labour_entries(reverses_labour_entry_id) '
        'WHERE reverses_labour_entry_id IS NOT NULL;',

    // Payments (lookup + single reversal + idempotency)
    'CREATE INDEX IF NOT EXISTS idx_payments_member_tx '
        'ON payments(member_id, transaction_at DESC);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_single_reversal '
        'ON payments(reverses_payment_id) '
        'WHERE reverses_payment_id IS NOT NULL;',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_client_request_id '
        'ON payments(client_request_id) '
        'WHERE client_request_id IS NOT NULL;',

    // Attachments & Audit logs
    'CREATE INDEX IF NOT EXISTS idx_attachments_entity '
        'ON attachments(entity_type, entity_id) WHERE deleted_at IS NULL;',
    'CREATE INDEX IF NOT EXISTS idx_audit_entity '
        'ON audit_logs(entity_type, entity_id, recorded_at DESC);',
  ];

  /// Additive indexes introduced in schema v2 (`worker_ledger_adjustments`).
  static const List<String> v2IndexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_wla_member_tx '
        'ON worker_ledger_adjustments(member_id, transaction_at DESC);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_wla_single_reversal '
        'ON worker_ledger_adjustments(reverses_adjustment_id) '
        'WHERE reverses_adjustment_id IS NOT NULL;',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_wla_client_request_id '
        'ON worker_ledger_adjustments(client_request_id) '
        'WHERE client_request_id IS NOT NULL;',
  ];

  /// Additive read-performance indexes introduced in schema v3 (V1.2).
  /// Zero tables or columns altered; speeds up date-range reports, insights,
  /// daily workshop summaries, and backup-age notification checks.
  static const List<String> v3IndexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_sm_tx_type '
        'ON stock_movements(transaction_at DESC, movement_type);',
    'CREATE INDEX IF NOT EXISTS idx_labour_tx_payable '
        'ON labour_entries(transaction_at DESC, is_payable);',
    'CREATE INDEX IF NOT EXISTS idx_payments_tx '
        'ON payments(transaction_at DESC, payment_type);',
    'CREATE INDEX IF NOT EXISTS idx_wla_tx '
        'ON worker_ledger_adjustments(transaction_at DESC);',
    'CREATE INDEX IF NOT EXISTS idx_audit_action_rec '
        'ON audit_logs(action_type, recorded_at DESC);',
  ];

  /// Additive indexes introduced in schema v4 (V1.3 Multi-Process Routing &
  /// Material Handover Management).
  static const List<String> v4IndexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_jp_lot_seq '
        'ON job_processes(lot_id, sequence_order) WHERE deleted_at IS NULL;',
    'CREATE INDEX IF NOT EXISTS idx_jp_design_colour '
        'ON job_processes(design_colour_id, status) WHERE deleted_at IS NULL;',
    'CREATE INDEX IF NOT EXISTS idx_jp_member_status '
        'ON job_processes(member_id, status) WHERE deleted_at IS NULL;',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_ph_transfer_ref '
        'ON process_handovers(transfer_reference);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_ph_client_request_id '
        'ON process_handovers(client_request_id) '
        'WHERE client_request_id IS NOT NULL;',
    'CREATE INDEX IF NOT EXISTS idx_ph_lot_tx '
        'ON process_handovers(lot_id, transaction_at ASC, recorded_at ASC);',
    'CREATE INDEX IF NOT EXISTS idx_ph_from_member '
        'ON process_handovers(from_member_id, transaction_at DESC);',
    'CREATE INDEX IF NOT EXISTS idx_ph_to_member '
        'ON process_handovers(to_member_id, transaction_at DESC);',
  ];

  /// Additive indexes introduced in schema v5 (V1.3 Dynamic Pricing,
  /// Additional Charges, and Immutable Rate Change History).
  static const List<String> v5IndexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_pac_lot '
        'ON process_additional_charges(lot_id, transaction_at ASC);',
    'CREATE INDEX IF NOT EXISTS idx_pac_job_process '
        'ON process_additional_charges(job_process_id);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_pac_client_request_id '
        'ON process_additional_charges(client_request_id) '
        'WHERE client_request_id IS NOT NULL;',
    'CREATE INDEX IF NOT EXISTS idx_prh_process '
        'ON process_rate_history(process_id, changed_at DESC);',
    'CREATE INDEX IF NOT EXISTS idx_prh_job_process '
        'ON process_rate_history(job_process_id, changed_at DESC);',
  ];

  /// Additive indexes introduced in schema v6 (`colour_master`).
  static const List<String> v6IndexStatements = [
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_colour_master_name '
        'ON colour_master(lower(name)) WHERE deleted_at IS NULL;',
    'CREATE INDEX IF NOT EXISTS idx_colour_master_recent '
        'ON colour_master(last_used_at DESC) WHERE deleted_at IS NULL;',
  ];

  /// Additive read-performance indexes introduced in schema v7 (V1.3 DB optimization).
  /// Zero tables or columns altered; eliminates full-table scans on lot-scoped
  /// stock movement lookups, rate-lock checks, and active lot listing.
  static const List<String> v7IndexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_sm_lot_tx '
        'ON stock_movements(lot_id, transaction_at ASC, recorded_at ASC);',
    'CREATE INDEX IF NOT EXISTS idx_sm_source_rate '
        'ON stock_movements(source_rate_id) '
        'WHERE source_rate_id IS NOT NULL;',
    'CREATE INDEX IF NOT EXISTS idx_lots_active_tx '
        'ON lots(transaction_at DESC) WHERE deleted_at IS NULL;',
  ];

  static const List<String> allIndexStatements = [
    ...v1IndexStatements,
    ...v2IndexStatements,
    ...v3IndexStatements,
    ...v4IndexStatements,
    ...v5IndexStatements,
    ...v6IndexStatements,
    ...v7IndexStatements,
  ];
}
