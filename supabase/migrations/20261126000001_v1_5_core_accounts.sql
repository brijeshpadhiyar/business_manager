-- ============================================================================
-- StitchFlow v1.5 — Migration 1: Core Accounts, Businesses & Devices
-- Single-owner multi-device architecture (team-ready via business_id)
-- ============================================================================

-- Generic server-side timestamp trigger function (immune to client clock skew)
CREATE OR REPLACE FUNCTION public.stitchflow_set_server_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.server_updated_at = now();
  RETURN NEW;
END;
$$;

-- 1. Businesses (one default workspace per owner in v1.5; expandable to teams)
CREATE TABLE IF NOT EXISTS public.businesses (
  id TEXT NOT NULL PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name_en TEXT NOT NULL DEFAULT 'Business Manager',
  name_gu TEXT NOT NULL DEFAULT 'બિઝનેસ મેનેજર',
  created_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  updated_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_businesses_owner ON public.businesses(owner_id);

DROP TRIGGER IF EXISTS trg_businesses_server_updated_at ON public.businesses;
CREATE TRIGGER trg_businesses_server_updated_at
  BEFORE INSERT OR UPDATE ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.stitchflow_set_server_updated_at();

-- 2. User Profiles (1:1 with auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NULL,
  email TEXT NULL,
  phone TEXT NULL,
  default_business_id TEXT NULL REFERENCES public.businesses(id) ON DELETE SET NULL,
  created_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  updated_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_user_profiles_server_updated_at ON public.user_profiles;
CREATE TRIGGER trg_user_profiles_server_updated_at
  BEFORE INSERT OR UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.stitchflow_set_server_updated_at();

-- 3. User Devices (tracks devices synced to the owner's business)
CREATE TABLE IF NOT EXISTS public.user_devices (
  id TEXT NOT NULL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_id TEXT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  device_name TEXT NOT NULL,
  platform TEXT NOT NULL,
  app_version TEXT NOT NULL,
  last_synced_at BIGINT NULL,
  created_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  updated_at BIGINT NOT NULL DEFAULT (extract(epoch FROM now()) * 1000)::BIGINT,
  server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_devices_user ON public.user_devices(user_id);

DROP TRIGGER IF EXISTS trg_user_devices_server_updated_at ON public.user_devices;
CREATE TRIGGER trg_user_devices_server_updated_at
  BEFORE INSERT OR UPDATE ON public.user_devices
  FOR EACH ROW EXECUTE FUNCTION public.stitchflow_set_server_updated_at();

-- 4. Lightweight Realtime wake-up table (avoids broadcasting 23 heavy tables)
CREATE TABLE IF NOT EXISTS public.sync_notifications (
  business_id TEXT NOT NULL PRIMARY KEY REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_device_id TEXT NULL,
  last_table TEXT NULL,
  last_change_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sync_notifications_owner ON public.sync_notifications(owner_id);

-- Auto-provision default business + user profile on new auth.users signup
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
    user_id,
    display_name,
    email,
    phone,
    default_business_id,
    created_at,
    updated_at
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

  INSERT INTO public.sync_notifications (business_id, owner_id, last_change_at)
  VALUES (v_business_id, NEW.id, now())
  ON CONFLICT (business_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.stitchflow_handle_new_user();
