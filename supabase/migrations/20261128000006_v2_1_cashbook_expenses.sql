-- ============================================================================
-- StitchFlow v2.1 — Migration 6: Workshop Expenses & Unified Cash/Bank Book
-- (Mirror of Drift Schema v13)
-- ============================================================================

-- 1. Allow 'WORKSHOP_EXPENSE' in attachments.entity_type
ALTER TABLE public.attachments
  DROP CONSTRAINT IF EXISTS attachments_entity_type_check;
ALTER TABLE public.attachments
  ADD CONSTRAINT attachments_entity_type_check
  CHECK (entity_type IN ('LOT', 'STOCK_MOVEMENT', 'PAYMENT', 'BUSINESS_PROFILE', 'WORKSHOP_EXPENSE'));

-- 2. workshop_expenses
CREATE TABLE IF NOT EXISTS public.workshop_expenses (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  category TEXT NOT NULL CHECK(category IN ('RENT', 'ELECTRICITY', 'MACHINE_REPAIR', 'STAFF_SALARY', 'SUPPLIES', 'REFRESHMENTS', 'TRANSPORT', 'OTHER')),
  title TEXT NOT NULL CHECK(length(trim(title)) > 0),
  payee_name TEXT NULL,
  amount_paise BIGINT NOT NULL CHECK(amount_paise > 0),
  payment_status TEXT NOT NULL CHECK(payment_status IN ('PAID', 'UNPAID')),
  payment_mode TEXT NULL CHECK(payment_mode IS NULL OR payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE')),
  reference_no TEXT NULL,
  reverses_expense_id TEXT NULL,
  client_request_id TEXT NULL,
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
  FOREIGN KEY (business_id, reverses_expense_id)
    REFERENCES public.workshop_expenses(business_id, id) ON DELETE RESTRICT
);

-- 3. cashbook_entries
CREATE TABLE IF NOT EXISTS public.cashbook_entries (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  entry_type TEXT NOT NULL CHECK(entry_type IN ('OPENING_CASH', 'OPENING_BANK', 'CASH_TO_BANK', 'BANK_TO_CASH', 'CAPITAL_IN', 'OWNER_DRAWING', 'EXPENSE_SETTLEMENT', 'REVERSAL')),
  account_bucket TEXT NOT NULL CHECK(account_bucket IN ('CASH', 'BANK', 'BOTH')),
  payment_mode TEXT NOT NULL CHECK(payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE')),
  amount_paise BIGINT NOT NULL CHECK(amount_paise >= 0),
  linked_expense_id TEXT NULL,
  reverses_entry_id TEXT NULL,
  client_request_id TEXT NULL,
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
  FOREIGN KEY (business_id, linked_expense_id)
    REFERENCES public.workshop_expenses(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_entry_id)
    REFERENCES public.cashbook_entries(business_id, id) ON DELETE RESTRICT
);

-- Indexes & server_updated_at triggers
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['workshop_expenses', 'cashbook_entries']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_server_updated_at ON public.%I', tbl, tbl);
    EXECUTE format(
      'CREATE TRIGGER trg_%I_server_updated_at BEFORE INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.stitchflow_set_server_updated_at()',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS idx_%I_sync ON public.%I(business_id, server_updated_at)',
      tbl, tbl
    );
  END LOOP;
END $$;

-- Role-aware RLS policies matching v2.1 RBAC matrix:
-- - OWNER, ACCOUNTANT, MANAGER can read workshop_expenses & cashbook_entries.
-- - OWNER & ACCOUNTANT can write workshop_expenses; MANAGER can insert PAID+CASH non-reversal expenses only.
-- - OWNER can write all cashbook_entries; ACCOUNTANT can write non-opening cashbook_entries.
DROP POLICY IF EXISTS "workshop_expenses_rbac_select" ON public.workshop_expenses;
DROP POLICY IF EXISTS "workshop_expenses_rbac_insert" ON public.workshop_expenses;
DROP POLICY IF EXISTS "workshop_expenses_rbac_update" ON public.workshop_expenses;

CREATE POLICY "workshop_expenses_rbac_select" ON public.workshop_expenses
  FOR SELECT USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'MANAGER', 'ACCOUNTANT'));

CREATE POLICY "workshop_expenses_rbac_insert" ON public.workshop_expenses
  FOR INSERT WITH CHECK (
    public.stitchflow_user_role(business_id) IN ('OWNER', 'ACCOUNTANT')
    OR (
      public.stitchflow_user_role(business_id) = 'MANAGER'
      AND payment_status = 'PAID'
      AND payment_mode = 'CASH'
      AND reverses_expense_id IS NULL
    )
  );

CREATE POLICY "workshop_expenses_rbac_update" ON public.workshop_expenses
  FOR UPDATE USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'ACCOUNTANT'))
  WITH CHECK (public.stitchflow_user_role(business_id) IN ('OWNER', 'ACCOUNTANT'));

DROP POLICY IF EXISTS "cashbook_entries_rbac_select" ON public.cashbook_entries;
DROP POLICY IF EXISTS "cashbook_entries_rbac_insert" ON public.cashbook_entries;
DROP POLICY IF EXISTS "cashbook_entries_rbac_update" ON public.cashbook_entries;

CREATE POLICY "cashbook_entries_rbac_select" ON public.cashbook_entries
  FOR SELECT USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'MANAGER', 'ACCOUNTANT'));

CREATE POLICY "cashbook_entries_rbac_insert" ON public.cashbook_entries
  FOR INSERT WITH CHECK (
    public.stitchflow_user_role(business_id) = 'OWNER'
    OR (
      public.stitchflow_user_role(business_id) = 'ACCOUNTANT'
      AND entry_type NOT IN ('OPENING_CASH', 'OPENING_BANK')
    )
  );

CREATE POLICY "cashbook_entries_rbac_update" ON public.cashbook_entries
  FOR UPDATE USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'ACCOUNTANT'))
  WITH CHECK (
    public.stitchflow_user_role(business_id) = 'OWNER'
    OR (
      public.stitchflow_user_role(business_id) = 'ACCOUNTANT'
      AND entry_type NOT IN ('OPENING_CASH', 'OPENING_BANK')
    )
  );
