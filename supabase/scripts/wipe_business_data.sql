-- ============================================================================
-- Wipe ALL business data from the Supabase cloud (go-live reset)
-- ============================================================================
-- DESTRUCTIVE. This permanently deletes every lot, worker, work stage, rate,
-- stock movement, payment, audit log and attachment record for EVERY business
-- in this Supabase project. It cannot be undone. Take a backup first
-- (Dashboard -> Database -> Backups) if anything here might be needed.
--
-- KEPT: sign-in accounts and team setup
--   auth.users, public.businesses, public.business_members,
--   public.user_profiles, public.user_devices
--
-- HOW TO RUN
--   1. Uninstall the app (or clear its data) on EVERY phone/PC that has
--      synced. A device that still holds old local rows will upload them
--      again after the wipe.
--   2. Supabase Dashboard -> SQL Editor -> paste this file -> Run.
--   3. Supabase Dashboard -> Storage -> bucket "stitchflow-media" ->
--      "Empty bucket" (Supabase blocks deleting storage files from SQL).
--   4. Install the fresh prod build and sign in.
-- ============================================================================

BEGIN;

TRUNCATE TABLE
  public.rejection_repairs,
  public.rejection_records,
  public.production_inspections,
  public.production_returns,
  public.process_additional_charges,
  public.process_handovers,
  public.process_rate_history,
  public.labour_entries,
  public.payments,
  public.worker_ledger_adjustments,
  public.job_processes,
  public.stock_movements,
  public.design_colours,
  public.lot_designs,
  public.lots,
  public.member_process_rates,
  public.member_processes,
  public.members,
  public.processes,
  public.colour_master,
  public.business_profile,
  public.attachments,
  public.audit_logs,
  public.cashbook_entries,
  public.workshop_expenses,
  public.sync_notifications,
  public.business_invites
CASCADE;

COMMIT;

-- Check: every count below should be 0.
SELECT 'lots' AS table_name, COUNT(*) FROM public.lots
UNION ALL SELECT 'members', COUNT(*) FROM public.members
UNION ALL SELECT 'processes', COUNT(*) FROM public.processes
UNION ALL SELECT 'stock_movements', COUNT(*) FROM public.stock_movements
UNION ALL SELECT 'payments', COUNT(*) FROM public.payments
UNION ALL SELECT 'audit_logs', COUNT(*) FROM public.audit_logs;
