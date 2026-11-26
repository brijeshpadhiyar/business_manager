-- ============================================================================
-- StitchFlow v1.5 — Migration 3: Row-Level Security, Realtime & Cloud Storage
-- ============================================================================

-- 1. Core Account Tables RLS
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "businesses_owner_all" ON public.businesses;
CREATE POLICY "businesses_owner_all" ON public.businesses
  FOR ALL USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "user_profiles_self_all" ON public.user_profiles;
CREATE POLICY "user_profiles_self_all" ON public.user_profiles
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "user_devices_self_all" ON public.user_devices;
CREATE POLICY "user_devices_self_all" ON public.user_devices
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "sync_notifications_owner_all" ON public.sync_notifications;
CREATE POLICY "sync_notifications_owner_all" ON public.sync_notifications
  FOR ALL USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());

-- 2. Domain Tables RLS (strict owner_id = auth.uid() + no DELETE on append-only ledgers)
DO $$
DECLARE
  tbl TEXT;
  mutable_tables TEXT[] := ARRAY[
    'attachments', 'business_profile', 'colour_master', 'processes', 'members',
    'member_processes', 'member_process_rates', 'lots', 'lot_designs',
    'design_colours', 'job_processes', 'rejection_records', 'rejection_repairs'
  ];
  append_only_tables TEXT[] := ARRAY[
    'stock_movements', 'process_handovers', 'process_additional_charges',
    'process_rate_history', 'labour_entries', 'payments',
    'worker_ledger_adjustments', 'production_returns',
    'production_inspections', 'audit_logs'
  ];
BEGIN
  FOREACH tbl IN ARRAY mutable_tables LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_all" ON public.%I;', tbl, tbl);
    EXECUTE format(
      'CREATE POLICY "%I_owner_all" ON public.%I FOR ALL USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());',
      tbl, tbl
    );
  END LOOP;

  FOREACH tbl IN ARRAY append_only_tables LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_select" ON public.%I;', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_insert" ON public.%I;', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS "%I_owner_update" ON public.%I;', tbl, tbl);
    EXECUTE format(
      'CREATE POLICY "%I_owner_select" ON public.%I FOR SELECT USING (owner_id = auth.uid());',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE POLICY "%I_owner_insert" ON public.%I FOR INSERT WITH CHECK (owner_id = auth.uid());',
      tbl, tbl
    );
    -- Allow idempotent upsert/soft-delete updates by owner while forbidding hard DELETE
    EXECUTE format(
      'CREATE POLICY "%I_owner_update" ON public.%I FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());',
      tbl, tbl
    );
  END LOOP;
END $$;

-- 3. Supabase Realtime Publication for sync_notifications
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'sync_notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sync_notifications;
  END IF;
END $$;

-- 4. Private Storage Bucket for Lot Photos & Business Logo (stitchflow-media)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'stitchflow-media',
  'stitchflow-media',
  FALSE,
  10485760, -- 10 MB max per image
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: object key format is `<owner_id>/<business_id>/<sha256>.<ext>`
DROP POLICY IF EXISTS "stitchflow_media_owner_select" ON storage.objects;
CREATE POLICY "stitchflow_media_owner_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'stitchflow-media'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

DROP POLICY IF EXISTS "stitchflow_media_owner_insert" ON storage.objects;
CREATE POLICY "stitchflow_media_owner_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'stitchflow-media'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

DROP POLICY IF EXISTS "stitchflow_media_owner_update" ON storage.objects;
CREATE POLICY "stitchflow_media_owner_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'stitchflow-media'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

DROP POLICY IF EXISTS "stitchflow_media_owner_delete" ON storage.objects;
CREATE POLICY "stitchflow_media_owner_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'stitchflow-media'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );
