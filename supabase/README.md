# StitchFlow v1.5 — Supabase Setup Guide (Dev & Prod)

StitchFlow v1.5 uses **two isolated Supabase projects** matching the Flutter flavors (`dev` and `prod`).

## 1. Create Projects & Apply Migrations
1. Create two Supabase projects: `stitchflow-dev` and `stitchflow-prod` (region: `ap-south-1` Mumbai recommended).
2. Run the 3 SQL migrations in order via Supabase CLI (`supabase db push`) or the Supabase SQL Editor:
   - `supabase/migrations/20261126000001_v1_5_core_accounts.sql`
   - `supabase/migrations/20261126000002_v1_5_domain_tables.sql`
   - `supabase/migrations/20261126000003_v1_5_rls_realtime_storage.sql`

## 2. Configure Authentication Providers

### Google Sign-In
1. In Google Cloud Console, create:
   - **Web OAuth 2.0 Client ID** (add `https://<project-ref>.supabase.co/auth/v1/callback` as Authorized Redirect URI).
   - **Android OAuth 2.0 Client ID** for `com.brijesh.stitchflow.dev` (debug SHA-1) and `com.brijesh.stitchflow` (release SHA-1).
   - **iOS OAuth 2.0 Client ID** (optional, for iOS builds).
2. In Supabase Dashboard → **Authentication → Providers → Google**:
   - Enable Google, paste Web Client ID & Client Secret.
   - Add `stitchflow://login-callback` under **Authentication → URL Configuration → Redirect URLs**.

### Phone Number (OTP)
- **Dev project:** In Supabase Dashboard → **Authentication → Providers → Phone**, enable Phone provider and add **Test Phone Numbers** (e.g. `919876543210=123456`) for instant zero-cost testing.
- **Prod project:** Enable Phone provider and configure **MSG91** (recommended for India `+91`) or **Twilio** with your Sender ID / DLT template.

### Identity Linking
- In Supabase Dashboard → **Authentication → Settings**, ensure **Enable Manual Linking** is turned **ON** so users can link both Google and Phone Number to the same StitchFlow account.

## 3. Supply Local Flavor Credentials
Copy `config/dev.json` to `config/dev.local.json` (git-ignored) and fill in your `dev` project values:
```json
{
  "APP_FLAVOR": "dev",
  "ENABLE_DEBUG_LOGS": "true",
  "DATABASE_NAME": "business_manager_dev.sqlite",
  "MEDIA_DIR_NAME": "media_dev",
  "SUPABASE_URL": "https://your-dev-ref.supabase.co",
  "SUPABASE_ANON_KEY": "your-dev-anon-key",
  "GOOGLE_WEB_CLIENT_ID": "your-web-client-id.apps.googleusercontent.com",
  "GOOGLE_IOS_CLIENT_ID": ""
}
```
Run with:
```powershell
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json
```
