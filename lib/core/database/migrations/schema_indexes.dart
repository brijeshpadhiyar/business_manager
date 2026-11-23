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
}
