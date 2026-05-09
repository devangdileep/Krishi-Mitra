# Production Readiness Report

## Codebase Audit

Current Flutter layers:

- `app`: app state, login session, theme/language preferences.
- `ui`: login, farm dashboard, farmland editor, reports, alerts, profile, voice assistant.
- `services`: Supabase REST, Open-Meteo, Groq AI, local persistence.
- `models`: farm, crop, weather, report, alert, and user models.
- `supabase`: SQL migrations and RLS policy baseline.

## Implemented Improvements

- Removed the old Kotlin Android app and Python backend prototype.
- Promoted Flutter to the repository root.
- Generated Android, iOS, and web platform folders.
- Converted Android Gradle from Kotlin DSL to Groovy.
- Kept Android host code Java-only.
- Added Android and iOS permissions for location, microphone, speech recognition, and internet.
- Added a Flutter smoke test for the real app entry point.
- Updated README, gitignore, and migration docs to match the Flutter-only structure.

## Performance Notes

- Dashboard loads cached farms before network refresh.
- Farm saves use optimistic local persistence.
- AI report generation reuses local cache where possible.
- Weather calls are isolated behind a service for future batching and cache upgrades.
- UI avoids native Android dependencies and runs from one Flutter rendering path.

## Database Improvements

Existing Supabase migrations include:

- User profiles and preferences.
- Farmlands with boundary points and heat scoring.
- Crop lifecycle tables.
- AI report cache tables.
- Weather cache tables.
- Farm tasks and notification queue.
- Farm image metadata for upload queues.
- Market prices and marketplace listings.
- Sync event log and geospatial indexes.

## Security Improvements

Implemented:

- Supabase and Groq keys are injected through `--dart-define`.
- Supabase service role keys are not used in mobile code.
- Platform permissions are explicit.

Required before production:

- Move Groq calls into Supabase Edge Functions.
- Rotate any keys pasted during development.
- Replace demo phone login with Supabase Auth OTP/session handling.
- Encrypt local auth/session state.
- Enforce ownership-based RLS on every user-owned table.

## Testing Report

Validation checklist for this migration:

- `flutter pub get`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `rg --files -g '*.kt' -g '*.kts'`

## Production Checklist

- [x] Flutter source at repo root.
- [x] Kotlin source removed.
- [x] Kotlin Gradle DSL removed.
- [x] Java-only Android host.
- [x] Android/iOS/web platform folders generated.
- [x] Flutter app smoke test added.
- [x] Supabase migration docs retained.
- [ ] Supabase Auth OTP migration.
- [ ] Edge Function AI proxy.
- [ ] Drift/Isar offline database.
- [ ] Image compression/upload queue.
- [ ] Full i18n string resources.
- [ ] Crash reporting and analytics.
- [ ] Automated E2E offline tests.

## Scalability Recommendations

- Use Supabase Edge Functions for Groq orchestration, batching, and rate limits.
- Add a batched `/sync` RPC function instead of per-row REST mutations.
- Cache weather by grid/region instead of individual farm.
- Use PostGIS `ST_Intersects` for regional pest/weather alerts.
- Store image originals in Supabase Storage and thumbnails separately.
- Add signed URL caching for image-heavy screens.
