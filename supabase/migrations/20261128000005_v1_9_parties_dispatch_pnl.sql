-- ============================================================================
-- StitchFlow v1.9 — Migration 5: Parties, Dispatch Challans, Buyer Returns,
-- Party Payments & Lot Direct Costs (Mirror of Drift Schema v12)
-- ============================================================================

-- 1. parties
CREATE TABLE IF NOT EXISTS public.parties (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  name TEXT NOT NULL CHECK(length(trim(name)) > 0),
  phone TEXT NULL,
  address TEXT NULL,
  party_type TEXT NOT NULL DEFAULT 'BOTH' CHECK(party_type IN ('BUYER', 'JOB_CLIENT', 'BOTH')),
  gstin TEXT NULL,
  opening_balance_paise BIGINT NOT NULL DEFAULT 0,
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

-- 2. dispatch_challans
CREATE TABLE IF NOT EXISTS public.dispatch_challans (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  challan_number TEXT NOT NULL CHECK(length(trim(challan_number)) > 0),
  party_id TEXT NOT NULL,
  reverses_challan_id TEXT NULL,
  client_request_id TEXT NULL,
  gross_amount_paise BIGINT NOT NULL CHECK(gross_amount_paise >= 0),
  discount_paise BIGINT NOT NULL DEFAULT 0 CHECK(discount_paise >= 0),
  other_charges_paise BIGINT NOT NULL DEFAULT 0 CHECK(other_charges_paise >= 0),
  net_amount_paise BIGINT NOT NULL CHECK(net_amount_paise >= 0),
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
  FOREIGN KEY (business_id, party_id)
    REFERENCES public.parties(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_challan_id)
    REFERENCES public.dispatch_challans(business_id, id) ON DELETE RESTRICT
);

-- 3. dispatch_items
CREATE TABLE IF NOT EXISTS public.dispatch_items (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  challan_id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  rate_paise BIGINT NOT NULL CHECK(rate_paise >= 0),
  line_total_paise BIGINT NOT NULL CHECK(line_total_paise >= 0),
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, challan_id)
    REFERENCES public.dispatch_challans(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_id)
    REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id)
    REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id)
    REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT
);

-- 4. buyer_returns
CREATE TABLE IF NOT EXISTS public.buyer_returns (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  return_number TEXT NOT NULL CHECK(length(trim(return_number)) > 0),
  party_id TEXT NOT NULL,
  challan_id TEXT NULL,
  reverses_return_id TEXT NULL,
  client_request_id TEXT NULL,
  credit_amount_paise BIGINT NOT NULL CHECK(credit_amount_paise >= 0),
  reason TEXT NOT NULL CHECK(length(trim(reason)) > 0),
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
  FOREIGN KEY (business_id, party_id)
    REFERENCES public.parties(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, challan_id)
    REFERENCES public.dispatch_challans(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_return_id)
    REFERENCES public.buyer_returns(business_id, id) ON DELETE RESTRICT
);

-- 5. buyer_return_items
CREATE TABLE IF NOT EXISTS public.buyer_return_items (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  buyer_return_id TEXT NOT NULL,
  dispatch_item_id TEXT NULL,
  lot_id TEXT NOT NULL,
  lot_design_id TEXT NOT NULL,
  design_colour_id TEXT NOT NULL,
  return_condition TEXT NOT NULL CHECK(return_condition IN ('GOOD', 'DAMAGED')),
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  rate_paise BIGINT NOT NULL CHECK(rate_paise >= 0),
  line_credit_paise BIGINT NOT NULL CHECK(line_credit_paise >= 0),
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, buyer_return_id)
    REFERENCES public.buyer_returns(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, dispatch_item_id)
    REFERENCES public.dispatch_items(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_id)
    REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, lot_design_id)
    REFERENCES public.lot_designs(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, design_colour_id)
    REFERENCES public.design_colours(business_id, id) ON DELETE RESTRICT
);

-- 6. party_payments
CREATE TABLE IF NOT EXISTS public.party_payments (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  party_id TEXT NOT NULL,
  challan_id TEXT NULL,
  reverses_payment_id TEXT NULL,
  client_request_id TEXT NULL,
  payment_type TEXT NOT NULL CHECK(payment_type IN ('RECEIPT', 'ADVANCE', 'REFUND', 'REVERSAL')),
  payment_mode TEXT NOT NULL CHECK(payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'OTHER')),
  amount_paise BIGINT NOT NULL CHECK(amount_paise > 0),
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
  FOREIGN KEY (business_id, party_id)
    REFERENCES public.parties(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, challan_id)
    REFERENCES public.dispatch_challans(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_payment_id)
    REFERENCES public.party_payments(business_id, id) ON DELETE RESTRICT
);

-- 7. lot_direct_costs
CREATE TABLE IF NOT EXISTS public.lot_direct_costs (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL DEFAULT auth.uid(),
  id TEXT NOT NULL,
  lot_id TEXT NOT NULL,
  reverses_cost_id TEXT NULL,
  client_request_id TEXT NULL,
  category TEXT NOT NULL CHECK(category IN ('FABRIC', 'TRIMS', 'TRANSPORT', 'PACKING', 'OTHER')),
  description TEXT NOT NULL CHECK(length(trim(description)) > 0),
  amount_paise BIGINT NOT NULL CHECK(amount_paise > 0),
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
  FOREIGN KEY (business_id, lot_id)
    REFERENCES public.lots(business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, reverses_cost_id)
    REFERENCES public.lot_direct_costs(business_id, id) ON DELETE RESTRICT
);

-- Indexes & server_updated_at triggers
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'parties',
    'dispatch_challans',
    'dispatch_items',
    'buyer_returns',
    'buyer_return_items',
    'party_payments',
    'lot_direct_costs'
  ]
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

-- Role-aware RLS policies matching v1.7 RBAC matrix
DO $$
DECLARE
  tbl TEXT;
BEGIN
  -- Dispatch & Party operations: OWNER & MANAGER can write; all workspace members can read.
  FOREACH tbl IN ARRAY ARRAY[
    'parties',
    'dispatch_challans',
    'dispatch_items',
    'buyer_returns',
    'buyer_return_items'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_select" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_write" ON public.%I', tbl, tbl);
    EXECUTE format(
      'CREATE POLICY "%I_rbac_select" ON public.%I FOR SELECT USING (public.stitchflow_user_role(business_id) IS NOT NULL)',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE POLICY "%I_rbac_write" ON public.%I FOR ALL USING (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'')) WITH CHECK (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER''))',
      tbl, tbl
    );
  END LOOP;

  -- Party payments & Lot direct costs: OWNER, MANAGER & ACCOUNTANT can read;
  -- OWNER & ACCOUNTANT can insert/update party_payments; OWNER, MANAGER & ACCOUNTANT can manage lot_direct_costs.
  DROP POLICY IF EXISTS "party_payments_rbac_select" ON public.party_payments;
  DROP POLICY IF EXISTS "party_payments_rbac_insert" ON public.party_payments;
  DROP POLICY IF EXISTS "party_payments_rbac_update" ON public.party_payments;
  CREATE POLICY "party_payments_rbac_select" ON public.party_payments
    FOR SELECT USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'MANAGER', 'ACCOUNTANT'));
  CREATE POLICY "party_payments_rbac_insert" ON public.party_payments
    FOR INSERT WITH CHECK (public.stitchflow_user_role(business_id) IN ('OWNER', 'ACCOUNTANT'));
  CREATE POLICY "party_payments_rbac_update" ON public.party_payments
    FOR UPDATE USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'ACCOUNTANT'))
    WITH CHECK (public.stitchflow_user_role(business_id) IN ('OWNER', 'ACCOUNTANT'));

  DROP POLICY IF EXISTS "lot_direct_costs_rbac_select" ON public.lot_direct_costs;
  DROP POLICY IF EXISTS "lot_direct_costs_rbac_write" ON public.lot_direct_costs;
  CREATE POLICY "lot_direct_costs_rbac_select" ON public.lot_direct_costs
    FOR SELECT USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'MANAGER', 'ACCOUNTANT'));
  CREATE POLICY "lot_direct_costs_rbac_write" ON public.lot_direct_costs
    FOR ALL USING (public.stitchflow_user_role(business_id) IN ('OWNER', 'MANAGER', 'ACCOUNTANT'))
    WITH CHECK (public.stitchflow_user_role(business_id) IN ('OWNER', 'MANAGER', 'ACCOUNTANT'));
END $$;
