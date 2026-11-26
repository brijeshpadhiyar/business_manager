-- ============================================================================
-- StitchFlow v1.7 — Migration 4: Multi-User Team RBAC, Invites & Role-Aware RLS
-- Backwards-compatible & idempotent upgrade from v1.5 single-owner schema.
-- ============================================================================

-- 1. Business Members (maps auth.users to businesses with granular roles)
CREATE TABLE IF NOT EXISTS public.business_members (
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK(role IN ('OWNER', 'MANAGER', 'QC_INSPECTOR', 'ACCOUNTANT')),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'REVOKED')),
  display_name TEXT NULL,
  email TEXT NULL,
  phone TEXT NULL,
  invited_by UUID NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  joined_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  updated_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_business_members_user
  ON public.business_members(user_id, status);

DROP TRIGGER IF EXISTS trg_business_members_server_updated_at ON public.business_members;
CREATE TRIGGER trg_business_members_server_updated_at
  BEFORE INSERT OR UPDATE ON public.business_members
  FOR EACH ROW EXECUTE FUNCTION public.stitchflow_set_server_updated_at();

-- Backfill every existing business owner as an ACTIVE OWNER member
INSERT INTO public.business_members (business_id, user_id, role, status, display_name, email, phone, joined_at, updated_at)
SELECT
  b.id,
  b.owner_id,
  'OWNER',
  'ACTIVE',
  up.display_name,
  up.email,
  up.phone,
  b.created_at,
  b.updated_at
FROM public.businesses b
LEFT JOIN public.user_profiles up ON up.user_id = b.owner_id
ON CONFLICT (business_id, user_id) DO NOTHING;

-- 2. Business Invites (WhatsApp-friendly expiring join codes + optional phone/email lock)
CREATE TABLE IF NOT EXISTS public.business_invites (
  id TEXT NOT NULL PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK(role IN ('MANAGER', 'QC_INSPECTOR', 'ACCOUNTANT')),
  target_phone TEXT NULL,
  target_email TEXT NULL,
  expires_at BIGINT NOT NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  redeemed_by UUID NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  redeemed_at BIGINT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING', 'REDEEMED', 'REVOKED', 'EXPIRED')),
  created_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  updated_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_invites_biz
  ON public.business_invites(business_id, status);

DROP TRIGGER IF EXISTS trg_business_invites_server_updated_at ON public.business_invites;
CREATE TRIGGER trg_business_invites_server_updated_at
  BEFORE INSERT OR UPDATE ON public.business_invites
  FOR EACH ROW EXECUTE FUNCTION public.stitchflow_set_server_updated_at();

-- 3. Auto-insert OWNER membership on new signup
CREATE OR REPLACE FUNCTION public.stitchflow_handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id TEXT;
  v_now_ms BIGINT;
BEGIN
  v_business_id := 'biz_' || replace(NEW.id::TEXT, '-', '');
  v_now_ms := (extract(epoch FROM now()) * 1000)::BIGINT;

  INSERT INTO public.businesses (id, owner_id, created_at, updated_at)
  VALUES (v_business_id, NEW.id, v_now_ms, v_now_ms)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_profiles (
    user_id, display_name, email, phone, default_business_id, created_at, updated_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    NEW.email,
    NEW.phone,
    v_business_id,
    v_now_ms,
    v_now_ms
  )
  ON CONFLICT (user_id) DO UPDATE
    SET email = COALESCE(EXCLUDED.email, public.user_profiles.email),
        phone = COALESCE(EXCLUDED.phone, public.user_profiles.phone),
        updated_at = v_now_ms;

  INSERT INTO public.business_members (
    business_id, user_id, role, status, display_name, email, phone, joined_at, updated_at
  )
  VALUES (
    v_business_id,
    NEW.id,
    'OWNER',
    'ACTIVE',
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    NEW.email,
    NEW.phone,
    v_now_ms,
    v_now_ms
  )
  ON CONFLICT (business_id, user_id) DO NOTHING;

  INSERT INTO public.sync_notifications (business_id, owner_id, last_change_at)
  VALUES (v_business_id, NEW.id, now())
  ON CONFLICT (business_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- 4. Role Lookup & Atomic Invite Redemption RPCs (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.stitchflow_user_role(p_business_id TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
  FROM public.business_members
  WHERE business_id = p_business_id
    AND user_id = auth.uid()
    AND status = 'ACTIVE'
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.stitchflow_redeem_invite(p_code TEXT)
RETURNS TABLE(business_id TEXT, role TEXT, business_name_en TEXT, business_name_gu TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite public.business_invites%ROWTYPE;
  v_user_email TEXT;
  v_user_phone TEXT;
  v_user_name TEXT;
  v_now_ms BIGINT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  v_now_ms := (extract(epoch FROM now()) * 1000)::BIGINT;

  SELECT * INTO v_invite
  FROM public.business_invites
  WHERE upper(trim(code)) = upper(trim(p_code))
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_not_found';
  END IF;

  IF v_invite.status <> 'PENDING' THEN
    RAISE EXCEPTION 'invite_already_used';
  END IF;

  IF v_invite.expires_at < v_now_ms THEN
    UPDATE public.business_invites
      SET status = 'EXPIRED', updated_at = v_now_ms
      WHERE id = v_invite.id;
    RAISE EXCEPTION 'invite_expired';
  END IF;

  SELECT email, phone, display_name
    INTO v_user_email, v_user_phone, v_user_name
  FROM public.user_profiles
  WHERE user_id = auth.uid();

  IF v_invite.target_email IS NOT NULL AND trim(v_invite.target_email) <> '' THEN
    IF lower(COALESCE(v_user_email, '')) <> lower(trim(v_invite.target_email)) THEN
      RAISE EXCEPTION 'invite_email_mismatch';
    END IF;
  END IF;

  IF v_invite.target_phone IS NOT NULL AND trim(v_invite.target_phone) <> '' THEN
    IF regexp_replace(COALESCE(v_user_phone, ''), '[^0-9]', '', 'g')
       <> regexp_replace(v_invite.target_phone, '[^0-9]', '', 'g') THEN
      RAISE EXCEPTION 'invite_phone_mismatch';
    END IF;
  END IF;

  INSERT INTO public.business_members (
    business_id, user_id, role, status, display_name, email, phone, invited_by, joined_at, updated_at
  )
  VALUES (
    v_invite.business_id,
    auth.uid(),
    v_invite.role,
    'ACTIVE',
    v_user_name,
    v_user_email,
    v_user_phone,
    v_invite.created_by,
    v_now_ms,
    v_now_ms
  )
  ON CONFLICT (business_id, user_id) DO UPDATE
    SET role = EXCLUDED.role,
        status = 'ACTIVE',
        updated_at = v_now_ms;

  UPDATE public.business_invites
    SET status = 'REDEEMED',
        redeemed_by = auth.uid(),
        redeemed_at = v_now_ms,
        updated_at = v_now_ms
    WHERE id = v_invite.id;

  UPDATE public.user_profiles
    SET default_business_id = v_invite.business_id,
        updated_at = v_now_ms
    WHERE user_id = auth.uid();

  RETURN QUERY
  SELECT b.id, v_invite.role, b.name_en, b.name_gu
  FROM public.businesses b
  WHERE b.id = v_invite.business_id;
END;
$$;

-- 5. RLS for business_members, business_invites, businesses & sync_notifications
ALTER TABLE public.business_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_invites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "businesses_owner_all" ON public.businesses;
DROP POLICY IF EXISTS "businesses_member_select" ON public.businesses;
CREATE POLICY "businesses_member_select" ON public.businesses
  FOR SELECT USING (public.stitchflow_user_role(id) IS NOT NULL);
DROP POLICY IF EXISTS "businesses_owner_write" ON public.businesses;
CREATE POLICY "businesses_owner_write" ON public.businesses
  FOR ALL USING (public.stitchflow_user_role(id) = 'OWNER')
  WITH CHECK (public.stitchflow_user_role(id) = 'OWNER');

DROP POLICY IF EXISTS "business_members_select" ON public.business_members;
CREATE POLICY "business_members_select" ON public.business_members
  FOR SELECT USING (public.stitchflow_user_role(business_id) IS NOT NULL);
DROP POLICY IF EXISTS "business_members_owner_manage" ON public.business_members;
CREATE POLICY "business_members_owner_manage" ON public.business_members
  FOR ALL USING (public.stitchflow_user_role(business_id) = 'OWNER')
  WITH CHECK (public.stitchflow_user_role(business_id) = 'OWNER');

DROP POLICY IF EXISTS "business_invites_owner_manage" ON public.business_invites;
CREATE POLICY "business_invites_owner_manage" ON public.business_invites
  FOR ALL USING (public.stitchflow_user_role(business_id) = 'OWNER')
  WITH CHECK (public.stitchflow_user_role(business_id) = 'OWNER');

DROP POLICY IF EXISTS "sync_notifications_owner_all" ON public.sync_notifications;
DROP POLICY IF EXISTS "sync_notifications_member_all" ON public.sync_notifications;
CREATE POLICY "sync_notifications_member_all" ON public.sync_notifications
  FOR ALL USING (public.stitchflow_user_role(business_id) IS NOT NULL)
  WITH CHECK (public.stitchflow_user_role(business_id) IS NOT NULL);

-- 6. Role-Aware Domain Table RLS across all 23 Tables
DO $$
DECLARE
  tbl TEXT;
  ops_tables TEXT[] := ARRAY[
    'attachments', 'colour_master', 'processes', 'members',
    'member_processes', 'member_process_rates', 'lots', 'lot_designs',
    'design_colours', 'job_processes', 'process_handovers',
    'process_additional_charges', 'process_rate_history'
  ];
  qc_tables TEXT[] := ARRAY[
    'production_returns', 'production_inspections',
    'rejection_records', 'rejection_repairs', 'stock_movements'
  ];
  finance_tables TEXT[] := ARRAY[
    'payments', 'worker_ledger_adjustments', 'labour_entries'
  ];
BEGIN
  -- Business Profile: all active members read; OWNER writes
  EXECUTE 'DROP POLICY IF EXISTS "business_profile_owner_all" ON public.business_profile';
  EXECUTE 'DROP POLICY IF EXISTS "business_profile_rbac_select" ON public.business_profile';
  EXECUTE 'DROP POLICY IF EXISTS "business_profile_rbac_write" ON public.business_profile';
  EXECUTE 'CREATE POLICY "business_profile_rbac_select" ON public.business_profile FOR SELECT USING (public.stitchflow_user_role(business_id) IS NOT NULL)';
  EXECUTE 'CREATE POLICY "business_profile_rbac_write" ON public.business_profile FOR ALL USING (public.stitchflow_user_role(business_id) = ''OWNER'') WITH CHECK (public.stitchflow_user_role(business_id) = ''OWNER'')';

  -- Audit Logs: all active members can read & insert; never delete
  EXECUTE 'DROP POLICY IF EXISTS "audit_logs_owner_select" ON public.audit_logs';
  EXECUTE 'DROP POLICY IF EXISTS "audit_logs_owner_insert" ON public.audit_logs';
  EXECUTE 'DROP POLICY IF EXISTS "audit_logs_owner_update" ON public.audit_logs';
  EXECUTE 'DROP POLICY IF EXISTS "audit_logs_rbac_select" ON public.audit_logs';
  EXECUTE 'DROP POLICY IF EXISTS "audit_logs_rbac_insert" ON public.audit_logs';
  EXECUTE 'CREATE POLICY "audit_logs_rbac_select" ON public.audit_logs FOR SELECT USING (public.stitchflow_user_role(business_id) IS NOT NULL)';
  EXECUTE 'CREATE POLICY "audit_logs_rbac_insert" ON public.audit_logs FOR INSERT WITH CHECK (public.stitchflow_user_role(business_id) IS NOT NULL)';

  -- Operational Tables: all active members read; OWNER + MANAGER write
  FOREACH tbl IN ARRAY ops_tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_all" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_select" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_insert" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_update" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_select" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_write" ON public.%I', tbl, tbl);
    EXECUTE format('CREATE POLICY "%I_rbac_select" ON public.%I FOR SELECT USING (public.stitchflow_user_role(business_id) IS NOT NULL)', tbl, tbl);
    EXECUTE format('CREATE POLICY "%I_rbac_write" ON public.%I FOR ALL USING (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'')) WITH CHECK (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER''))', tbl, tbl);
  END LOOP;

  -- QC & Stock Tables: all active members read; OWNER + MANAGER + QC_INSPECTOR write
  FOREACH tbl IN ARRAY qc_tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_all" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_select" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_insert" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_update" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_select" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_write" ON public.%I', tbl, tbl);
    EXECUTE format('CREATE POLICY "%I_rbac_select" ON public.%I FOR SELECT USING (public.stitchflow_user_role(business_id) IS NOT NULL)', tbl, tbl);
    EXECUTE format('CREATE POLICY "%I_rbac_write" ON public.%I FOR ALL USING (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'', ''QC_INSPECTOR'')) WITH CHECK (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'', ''QC_INSPECTOR''))', tbl, tbl);
  END LOOP;

  -- Finance & Labour Tables: OWNER + MANAGER + ACCOUNTANT read (QC_INSPECTOR restricted); OWNER + ACCOUNTANT write (MANAGER/QC may insert labour_entries on settlement)
  FOREACH tbl IN ARRAY finance_tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_select" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_insert" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_update" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_select" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_insert" ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_rbac_update" ON public.%I', tbl, tbl);
    EXECUTE format('CREATE POLICY "%I_rbac_select" ON public.%I FOR SELECT USING (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'', ''ACCOUNTANT''))', tbl, tbl);
    IF tbl = 'labour_entries' THEN
      EXECUTE format('CREATE POLICY "%I_rbac_insert" ON public.%I FOR INSERT WITH CHECK (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'', ''QC_INSPECTOR'', ''ACCOUNTANT''))', tbl, tbl);
      EXECUTE format('CREATE POLICY "%I_rbac_update" ON public.%I FOR UPDATE USING (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'', ''ACCOUNTANT'')) WITH CHECK (public.stitchflow_user_role(business_id) IN (''OWNER'', ''MANAGER'', ''ACCOUNTANT''))', tbl, tbl);
    ELSE
      EXECUTE format('CREATE POLICY "%I_rbac_insert" ON public.%I FOR INSERT WITH CHECK (public.stitchflow_user_role(business_id) IN (''OWNER'', ''ACCOUNTANT''))', tbl, tbl);
      EXECUTE format('CREATE POLICY "%I_rbac_update" ON public.%I FOR UPDATE USING (public.stitchflow_user_role(business_id) IN (''OWNER'', ''ACCOUNTANT'')) WITH CHECK (public.stitchflow_user_role(business_id) IN (''OWNER'', ''ACCOUNTANT''))', tbl, tbl);
    END IF;
  END LOOP;
END $$;

-- 7. Team-Aware Storage Bucket RLS (2nd folder segment is business_id)
DROP POLICY IF EXISTS "stitchflow_media_owner_select" ON storage.objects;
DROP POLICY IF EXISTS "stitchflow_media_member_select" ON storage.objects;
CREATE POLICY "stitchflow_media_member_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'stitchflow-media'
    AND (
      (storage.foldername(name))[1] = auth.uid()::TEXT
      OR public.stitchflow_user_role((storage.foldername(name))[2]) IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "stitchflow_media_owner_insert" ON storage.objects;
DROP POLICY IF EXISTS "stitchflow_media_member_insert" ON storage.objects;
CREATE POLICY "stitchflow_media_member_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'stitchflow-media'
    AND (
      (storage.foldername(name))[1] = auth.uid()::TEXT
      OR public.stitchflow_user_role((storage.foldername(name))[2]) IN ('OWNER', 'MANAGER', 'QC_INSPECTOR', 'ACCOUNTANT')
    )
  );
