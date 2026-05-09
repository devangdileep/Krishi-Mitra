# Offline-First Sync Architecture

## Current Flutter Implementation

The Flutter app is local-first for the core farm workflow.

1. UI reads cached farms from `LocalStore` first.
2. Writes are persisted locally before network sync.
3. The UI updates immediately after local save.
4. Supabase refreshes run silently when network is available.
5. AI reports are cached by farm, weather, crops, and engine version.

This keeps the app usable in weak rural networks while still allowing Supabase to be the cloud source of truth.

## Local Data

- Logged-in farmer profile.
- Cached farmland records.
- Crops attached to each farm.
- Boundary polygon points.
- AI report cache.
- Weather/report preferences.
- Theme and language preferences.

## Sync Status Model

- `synced`: local data matches Supabase.
- `pending`: local mutation needs cloud sync.
- `failed`: mutation failed and should be retried.

## Conflict Strategy

Current app behavior:

- Local edits are trusted immediately.
- Server refreshes merge into local cache after successful fetch.
- AI reports and weather are cache data, so they are invalidated instead of merged.

Production upgrade:

- Add `sync_version`, `client_updated_at`, and `updated_at` to every mutable Supabase table.
- Resolve farmland polygon conflicts by preserving the latest user edit and storing boundary history.
- Merge crop tasks by task id.
- Treat market/weather records as server-owned read models.

## AI Cache Strategy

AI report cache key:

`farmlandId + crops + soil + boundary + heatIndex + weatherSummary + modelVersion`

Cache TTL:

- Cloud Groq report: 6 hours.
- Local fallback report: 45 minutes.

This prevents repeated Groq calls when the Report tab reopens or connectivity is weak.

## Next Production Steps

- Move Groq calls to Supabase Edge Functions.
- Add encrypted local storage for auth/session secrets.
- Replace SharedPreferences with Drift or Isar for scalable offline tables.
- Add an image upload queue with WebP compression.
- Add a server-side batched sync RPC endpoint.
