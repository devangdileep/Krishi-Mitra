# Supabase Backend

The Android app now talks directly to Supabase Data REST endpoints instead of the old FastAPI/ngrok server.

## Setup

1. Open the Supabase SQL editor for your project.
2. Run `supabase/migrations/0001_krishi_mitra_schema.sql`.
3. In Supabase, open **Project Settings > API Keys** and copy a publishable key or legacy anon key.
4. Add these values to `local.properties`:

```properties
SUPABASE_URL=https://kqozeorgqzltihbycnju.supabase.co
SUPABASE_API_KEY=your_publishable_or_anon_key
```

Do not put the database password, secret key, or service role key in the Android app. Mobile builds are public environments, so only a publishable or anon key belongs here.

## Tables

- `users`: phone-number based demo identity used by the existing OTP flow.
- `farmlands`: farm profiles with crop lists stored as `jsonb`.
- `pest_alerts`: community pest and disease reports.

The migration keeps Row Level Security enabled and adds permissive demo policies so the current hackathon OTP flow works without Supabase Auth. Before production, replace those policies with Supabase Auth-backed ownership checks.
