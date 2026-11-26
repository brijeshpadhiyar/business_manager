-- ============================================================================
-- StitchFlow v1.5 — Migration 2: Complete 23 Domain Tables (Mirror of Drift v9)
-- Composite Primary Key (business_id, id) ensures per-user isolation for
-- singleton/seeded IDs ('default', 'cm-red', etc.) and multi-tenant safety.
-- ============================================================================

-- 1. attachments
CREATE TABLE IF NOT EXISTS public.attachments (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  entity_type TEXT NOT NULL CHECK(entity_type IN ('LOT', 'STOCK_MOVEMENT', 'PAYMENT', 'BUSINESS_PROFILE')),
  entity_id TEXT NOT NULL,
  relative_path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  sha256 TEXT NOT NULL,
  caption TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id)
);

-- 2. business_profile
CREATE TABLE IF NOT EXISTS public.business_profile (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  name_en TEXT NOT NULL DEFAULT 'Business Manager',
  name_gu TEXT NOT NULL DEFAULT 'બિઝનેસ મેનેજર',
  owner_name TEXT NULL,
  phone TEXT NULL,
  address TEXT NULL,
  logo_attachment_id TEXT NULL,
  default_billing_mode TEXT NOT NULL DEFAULT 'RECEIVED_QTY'
    CHECK(default_billing_mode IN ('RECEIVED_QTY', 'GIVEN_QTY')),
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, logo_attachment_id)
    REFERENCES public.attachments(business_id, id) ON DELETE RESTRICT
);

-- 3. colour_master
CREATE TABLE IF NOT EXISTS public.colour_master (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  name TEXT NOT NULL CHECK(length(trim(name)) > 0),
  hex_code TEXT NOT NULL CHECK(length(trim(hex_code)) = 7),
  is_custom INTEGER NOT NULL DEFAULT 0 CHECK(is_custom IN (0, 1)),
  last_used_at BIGINT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id)
);

-- 4. processes
CREATE TABLE IF NOT EXISTS public.processes (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT NULL,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  billing_mode_override TEXT NULL
    CHECK(billing_mode_override IS NULL OR billing_mode_override IN ('RECEIVED_QTY', 'GIVEN_QTY')),
  include_damaged_in_labour INTEGER NOT NULL DEFAULT 0 CHECK(include_damaged_in_labour IN (0, 1)),
  default_rate_paise BIGINT NOT NULL DEFAULT 0,
  default_pricing_unit TEXT NOT NULL DEFAULT 'PER_PIECE',
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id)
);

-- 5. members
CREATE TABLE IF NOT EXISTS public.members (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NULL,
  address TEXT NULL,
  notes TEXT NULL,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id)
);

-- 6. member_processes
CREATE TABLE IF NOT EXISTS public.member_processes (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT
);

-- 7. member_process_rates
CREATE TABLE IF NOT EXISTS public.member_process_rates (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  rate_paise BIGINT NOT NULL CHECK(rate_paise >= 0),
  effective_from TEXT NOT NULL,
  effective_to TEXT NULL,
  notes TEXT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  CHECK(effective_to IS NULL OR effective_to >= effective_from),
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT
);

-- 8. lots
CREATE TABLE IF NOT EXISTS public.lots (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  lot_number TEXT NOT NULL,
  title TEXT NULL,
  notes TEXT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'COMPLETED', 'ARCHIVED')),
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id)
);

-- 9. lot_designs
CREATE TABLE IF NOT EXISTS public.lot_designs (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  design_name TEXT NOT NULL,
  notes TEXT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT
);

-- 10. design_colours
CREATE TABLE IF NOT EXISTS public.design_colours (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  colour_name TEXT NOT NULL,
  colour_hex TEXT NULL,
  initial_quantity INTEGER NOT NULL CHECK(initial_quantity > 0),
  unit_price_paise BIGINT NOT NULL DEFAULT 0 CHECK(unit_price_paise >= 0),
  notes TEXT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, lot_design_id) REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT
);

-- 11. stock_movements (append-only)
CREATE TABLE IF NOT EXISTS public.stock_movements (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  process_id TEXT NULL,
  member_id TEXT NULL,
  parent_issue_id TEXT NULL,
  job_process_id TEXT NULL,
  reverses_movement_id TEXT NULL,
  client_request_id TEXT NULL,
  movement_type TEXT NOT NULL CHECK(movement_type IN (
    'ISSUE', 'RETURN_GOOD', 'RETURN_DAMAGED', 'SETTLEMENT_LOST',
    'SETTLEMENT_SHORTAGE', 'ADJUSTMENT_DAMAGED_TO_GOOD', 'REVERSAL'
  )),
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  source_rate_id TEXT NULL,
  applied_rate_paise BIGINT NOT NULL DEFAULT 0 CHECK(applied_rate_paise >= 0),
  is_rate_overridden INTEGER NOT NULL DEFAULT 0 CHECK(is_rate_overridden IN (0, 1)),
  override_reason TEXT NULL,
  locked_billing_mode TEXT NULL
    CHECK(locked_billing_mode IS NULL OR locked_billing_mode IN ('RECEIVED_QTY', 'GIVEN_QTY')),
  locked_include_damaged INTEGER NOT NULL DEFAULT 0 CHECK(locked_include_damaged IN (0, 1)),
  reason TEXT NULL,
  notes TEXT NULL,
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id) REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, parent_issue_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_movement_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, source_rate_id) REFERENCES public.member_process_rates(business_id, id) ON DELETE RESTRICT
);

-- 12. job_processes
CREATE TABLE IF NOT EXISTS public.job_processes (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  member_id TEXT NULL,
  sequence_order INTEGER NOT NULL DEFAULT 1,
  planned_quantity INTEGER NOT NULL CHECK(planned_quantity > 0),
  dispatched_quantity INTEGER NOT NULL DEFAULT 0 CHECK(dispatched_quantity >= 0),
  received_quantity INTEGER NOT NULL DEFAULT 0 CHECK(received_quantity >= 0),
  returned_to_factory_quantity INTEGER NOT NULL DEFAULT 0 CHECK(returned_to_factory_quantity >= 0),
  transferred_out_quantity INTEGER NOT NULL DEFAULT 0 CHECK(transferred_out_quantity >= 0),
  damaged_quantity INTEGER NOT NULL DEFAULT 0 CHECK(damaged_quantity >= 0),
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK(status IN (
    'DRAFT', 'PENDING', 'DISPATCHED', 'IN_PROGRESS', 'PARTIALLY_COMPLETED',
    'COMPLETED', 'PARTIALLY_RETURNED', 'RETURNED', 'TRANSFERRED', 'CANCELLED'
  )),
  source_job_process_id TEXT NULL,
  linked_issue_movement_id TEXT NULL,
  default_rate_paise BIGINT NOT NULL DEFAULT 0 CHECK(default_rate_paise >= 0),
  agreed_rate_paise BIGINT NOT NULL DEFAULT 0 CHECK(agreed_rate_paise >= 0),
  pricing_unit TEXT NOT NULL DEFAULT 'PER_PIECE',
  rate_override_reason TEXT NULL,
  payable_amount_paise BIGINT NOT NULL DEFAULT 0 CHECK(payable_amount_paise >= 0),
  paid_amount_paise BIGINT NOT NULL DEFAULT 0 CHECK(paid_amount_paise >= 0),
  payment_status TEXT NOT NULL DEFAULT 'PENDING'
    CHECK(payment_status IN ('PENDING', 'PARTIALLY_PAID', 'PAID')),
  notes TEXT NULL,
  transaction_at BIGINT NOT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id) REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, source_job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, linked_issue_movement_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT
);

-- 13. process_handovers (append-only)
CREATE TABLE IF NOT EXISTS public.process_handovers (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  transfer_reference TEXT NOT NULL,
  client_request_id TEXT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  handover_type TEXT NOT NULL CHECK(handover_type IN (
    'FACTORY_DISPATCH', 'DIRECT_TRANSFER', 'FACTORY_RETURN', 'REASSIGNMENT', 'CANCELLATION'
  )),
  from_job_process_id TEXT NULL,
  to_job_process_id TEXT NULL,
  from_member_id TEXT NULL,
  to_member_id TEXT NULL,
  process_id TEXT NOT NULL,
  quantity_dispatched INTEGER NOT NULL CHECK(quantity_dispatched >= 0),
  quantity_received INTEGER NOT NULL DEFAULT 0 CHECK(quantity_received >= 0),
  status TEXT NOT NULL DEFAULT 'PENDING_RECEIPT'
    CHECK(status IN ('PENDING_RECEIPT', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED')),
  linked_stock_movement_id TEXT NULL,
  notes TEXT NULL,
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  CHECK(quantity_received <= quantity_dispatched),
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id) REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, from_job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, to_job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, from_member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, to_member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, linked_stock_movement_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT
);

-- 14. process_additional_charges
CREATE TABLE IF NOT EXISTS public.process_additional_charges (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  job_process_id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  charge_type TEXT NOT NULL CHECK(charge_type IN ('EXTRA_CHARGE', 'DEDUCTION')),
  description TEXT NOT NULL CHECK(length(trim(description)) > 0),
  amount_paise BIGINT NOT NULL CHECK(amount_paise > 0),
  client_request_id TEXT NULL,
  created_by TEXT NULL,
  transaction_at BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  ledger_adjustment_id TEXT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT
);

-- 15. process_rate_history (append-only)
CREATE TABLE IF NOT EXISTS public.process_rate_history (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  scope TEXT NOT NULL CHECK(scope IN ('PROCESS_DEFAULT', 'JOB_ASSIGNMENT')),
  process_id TEXT NOT NULL,
  job_process_id TEXT NULL,
  member_id TEXT NULL,
  design_colour_id TEXT NULL,
  previous_rate_paise BIGINT NOT NULL CHECK(previous_rate_paise >= 0),
  new_rate_paise BIGINT NOT NULL CHECK(new_rate_paise >= 0),
  pricing_unit TEXT NOT NULL,
  reason TEXT NOT NULL CHECK(length(trim(reason)) > 0),
  changed_by TEXT NULL,
  changed_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT
);

-- 16. labour_entries (append-only)
CREATE TABLE IF NOT EXISTS public.labour_entries (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  stock_movement_id TEXT NOT NULL,
  reverses_labour_entry_id TEXT NULL,
  member_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  basis_type TEXT NOT NULL CHECK(basis_type IN ('ISSUED', 'RECEIVED_GOOD', 'RECEIVED_DAMAGED', 'REVERSAL')),
  quantity INTEGER NOT NULL,
  rate_paise BIGINT NOT NULL CHECK(rate_paise >= 0),
  amount_paise BIGINT NOT NULL,
  is_payable INTEGER NOT NULL CHECK(is_payable IN (0, 1)),
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, stock_movement_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_labour_entry_id) REFERENCES public.labour_entries(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT
);

-- 17. payments (append-only)
CREATE TABLE IF NOT EXISTS public.payments (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  payment_type TEXT NOT NULL CHECK(payment_type IN ('REGULAR', 'ADVANCE', 'ADVANCE_REFUND', 'REVERSAL')),
  reverses_payment_id TEXT NULL,
  client_request_id TEXT NULL,
  amount_paise BIGINT NOT NULL CHECK(amount_paise > 0),
  payment_mode TEXT NOT NULL CHECK(payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'OTHER')),
  reference_no TEXT NULL,
  reason TEXT NULL,
  notes TEXT NULL,
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_payment_id) REFERENCES public.payments(business_id, id) ON DELETE RESTRICT
);

-- 18. worker_ledger_adjustments (append-only)
CREATE TABLE IF NOT EXISTS public.worker_ledger_adjustments (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  adjustment_type TEXT NOT NULL CHECK(adjustment_type IN ('CREDIT', 'DEBIT', 'REVERSAL')),
  reverses_adjustment_id TEXT NULL,
  client_request_id TEXT NULL,
  amount_paise BIGINT NOT NULL CHECK(amount_paise > 0),
  reason TEXT NOT NULL CHECK(length(trim(reason)) > 0),
  source_charge_id TEXT NULL,
  job_process_id TEXT NULL,
  notes TEXT NULL,
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_by TEXT NULL,
  updated_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_adjustment_id) REFERENCES public.worker_ledger_adjustments(business_id, id) ON DELETE RESTRICT
);

-- 19. production_returns (append-only)
CREATE TABLE IF NOT EXISTS public.production_returns (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  client_request_id TEXT NULL,
  parent_issue_id TEXT NOT NULL,
  job_process_id TEXT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  returned_quantity INTEGER NOT NULL CHECK(returned_quantity > 0),
  return_mode TEXT NOT NULL DEFAULT 'PENDING_INSPECTION'
    CHECK(return_mode IN ('PENDING_INSPECTION', 'IMMEDIATE_INSPECTION')),
  notes TEXT NULL,
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_by TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, parent_issue_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id) REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT
);

-- 20. production_inspections (append-only)
CREATE TABLE IF NOT EXISTS public.production_inspections (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  client_request_id TEXT NULL,
  inspection_type TEXT NOT NULL DEFAULT 'INITIAL' CHECK(inspection_type IN ('INITIAL', 'REINSPECTION')),
  production_return_id TEXT NULL,
  rejection_record_id TEXT NULL,
  rejection_repair_id TEXT NULL,
  parent_issue_id TEXT NOT NULL,
  job_process_id TEXT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  accepted_quantity INTEGER NOT NULL DEFAULT 0 CHECK(accepted_quantity >= 0),
  rejected_quantity INTEGER NOT NULL DEFAULT 0 CHECK(rejected_quantity >= 0),
  locked_rate_paise BIGINT NOT NULL DEFAULT 0 CHECK(locked_rate_paise >= 0),
  earned_amount_paise BIGINT NOT NULL DEFAULT 0 CHECK(earned_amount_paise >= 0),
  credit_worker_earnings INTEGER NOT NULL DEFAULT 1 CHECK(credit_worker_earnings IN (0, 1)),
  linked_good_movement_id TEXT NULL,
  linked_damaged_movement_id TEXT NULL,
  linked_labour_entry_id TEXT NULL,
  rejection_reason TEXT NULL,
  notes TEXT NULL,
  inspected_by TEXT NULL,
  approved_by TEXT NULL,
  authorized_via_pin INTEGER NOT NULL DEFAULT 0 CHECK(authorized_via_pin IN (0, 1)),
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  CHECK(accepted_quantity + rejected_quantity > 0),
  FOREIGN KEY (business_id, production_return_id) REFERENCES public.production_returns(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, parent_issue_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id) REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, linked_good_movement_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, linked_damaged_movement_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, linked_labour_entry_id) REFERENCES public.labour_entries(business_id, id) ON DELETE RESTRICT
);

-- 21. rejection_records
CREATE TABLE IF NOT EXISTS public.rejection_records (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  parent_issue_id TEXT NOT NULL,
  job_process_id TEXT NULL,
  production_return_id TEXT NULL,
  inspection_id TEXT NOT NULL,
  stock_movement_id TEXT NOT NULL,
  rejected_quantity INTEGER NOT NULL CHECK(rejected_quantity > 0),
  rejection_reason TEXT NOT NULL CHECK(length(trim(rejection_reason)) > 0),
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK(status IN (
    'OPEN', 'PARTIALLY_REPAIRED', 'REPAIRED_PENDING_INSPECTION',
    'PARTIALLY_REAPPROVED', 'REAPPROVED', 'SCRAPPED'
  )),
  inspected_at BIGINT NOT NULL,
  recorded_by TEXT NULL,
  notes TEXT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id) REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, parent_issue_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, job_process_id) REFERENCES public.job_processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, production_return_id) REFERENCES public.production_returns(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, inspection_id) REFERENCES public.production_inspections(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, stock_movement_id) REFERENCES public.stock_movements(business_id, id) ON DELETE RESTRICT
);

-- 22. rejection_repairs
CREATE TABLE IF NOT EXISTS public.rejection_repairs (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  client_request_id TEXT NULL,
  rejection_record_id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  process_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  repaired_quantity INTEGER NOT NULL CHECK(repaired_quantity > 0),
  repair_source TEXT NOT NULL DEFAULT 'ORIGINAL_WORKER'
    CHECK(repair_source IN ('ORIGINAL_WORKER', 'IN_HOUSE')),
  status TEXT NOT NULL DEFAULT 'PENDING_REINSPECTION'
    CHECK(status IN ('PENDING_REINSPECTION', 'PARTIALLY_REINSPECTED', 'COMPLETED')),
  repaired_by TEXT NULL,
  notes TEXT NULL,
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, rejection_record_id) REFERENCES public.rejection_records(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_id) REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id) REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, process_id) REFERENCES public.processes(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, member_id) REFERENCES public.members(business_id, id) ON DELETE RESTRICT
);

-- 23. audit_logs (append-only)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  action_type TEXT NOT NULL CHECK(action_type IN (
    'CREATE', 'UPDATE', 'SOFT_DELETE', 'DEACTIVATE', 'REACTIVATE',
    'RATE_OVERRIDE', 'REVERSAL', 'DAMAGED_TO_GOOD_ADJUSTMENT',
    'BACKUP_EXPORT', 'BACKUP_RESTORE'
  )),
  actor TEXT NULL,
  previous_value_json TEXT NULL,
  new_value_json TEXT NULL,
  reason TEXT NULL,
  transaction_at BIGINT NOT NULL,
  recorded_at BIGINT NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id)
);

-- ============================================================================
-- Sync Indexes & server_updated_at Triggers across all 23 domain tables
-- ============================================================================
DO $$
DECLARE
  tbl TEXT;
  all_tables TEXT[] := ARRAY[
    'attachments', 'business_profile', 'colour_master', 'processes', 'members',
    'member_processes', 'member_process_rates', 'lots', 'lot_designs',
    'design_colours', 'stock_movements', 'job_processes', 'process_handovers',
    'process_additional_charges', 'process_rate_history', 'labour_entries',
    'payments', 'worker_ledger_adjustments', 'production_returns',
    'production_inspections', 'rejection_records', 'rejection_repairs',
    'audit_logs'
  ];
BEGIN
  FOREACH tbl IN ARRAY all_tables LOOP
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS idx_%I_sync_cursor ON public.%I (business_id, server_updated_at ASC);',
      tbl, tbl
    );
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%I_server_updated_at ON public.%I;',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE TRIGGER trg_%I_server_updated_at BEFORE INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.stitchflow_set_server_updated_at();',
      tbl, tbl
    );
  END LOOP;
END $$;

-- Idempotency & single-reversal partial unique indexes scoped per business_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_sm_single_reversal
  ON public.stock_movements(business_id, reverses_movement_id)
  WHERE reverses_movement_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_sm_client_req
  ON public.stock_movements(business_id, client_request_id)
  WHERE client_request_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_labour_movement_basis
  ON public.labour_entries(business_id, stock_movement_id, basis_type);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_labour_single_reversal
  ON public.labour_entries(business_id, reverses_labour_entry_id)
  WHERE reverses_labour_entry_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_payments_single_reversal
  ON public.payments(business_id, reverses_payment_id)
  WHERE reverses_payment_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_payments_client_req
  ON public.payments(business_id, client_request_id)
  WHERE client_request_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_wla_single_reversal
  ON public.worker_ledger_adjustments(business_id, reverses_adjustment_id)
  WHERE reverses_adjustment_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_wla_client_req
  ON public.worker_ledger_adjustments(business_id, client_request_id)
  WHERE client_request_id IS NOT NULL;
