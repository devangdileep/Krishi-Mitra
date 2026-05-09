# Flutter Migration Notes

## Status

The migration is complete for this workspace. Krishi Mitra now runs from the root Flutter project:

- Dart application code: `lib/`
- Android host: `android/`
- iOS host: `ios/`
- Web host: `web/`
- Supabase SQL migrations: `supabase/migrations/`

The old Kotlin Android app and Python backend prototype were removed during cleanup. Android uses a Java host activity and Groovy Gradle files, so no Kotlin source or Kotlin Gradle DSL remains.

## Ported Features

- App-wide light/dark glassmorphism theme.
- Animated sun/moon dark-mode toggle.
- Supabase REST register/login and farmland CRUD.
- Offline-first farmland cache using local storage.
- AI farm report engine with Groq model fallback and local preview.
- Open-Meteo forecast integration.
- Farmer-friendly geofencing with current location, starter plot scan, GPS corner capture, map taps, area calculation, and heat overlay.
- Community alerts view.
- Voice assistant sheet with speech-to-text and TTS.

## Validation Commands

```bash
E:\flutter\bin\flutter.bat pub get
E:\flutter\bin\cache\dart-sdk\bin\dart.exe format lib test
E:\flutter\bin\flutter.bat analyze
E:\flutter\bin\flutter.bat test
E:\flutter\bin\flutter.bat build apk --debug
```

## Production Follow-Up

- Move Groq calls to Supabase Edge Functions before release.
- Replace SharedPreferences cache with Drift or Isar for large offline datasets.
- Add background sync workers using Workmanager.
- Add integration tests for login, farm save, geofence scan, report refresh, and dark-mode toggle.
