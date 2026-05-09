# Groq AI Setup

Krishi Mitra uses Groq for:

- voice assistant answers
- AI crop sustainability reports
- structured farm recommendations

## Local Development

Your local `.env` file is ignored by Git. Add:

```text
GROQ_API_KEY=your_groq_key
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_dev.ps1
```

or build a debug APK:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_dev.ps1 -BuildApk
```

Android Studio Gradle sync/builds also read `.env` and pass values into Flutter
as `dart-defines` for debug builds.

## Production

Do not compile `GROQ_API_KEY` into a production APK. Deploy
`supabase/functions/groq-ai` and set the secret in Supabase:

```powershell
supabase secrets set GROQ_API_KEY=your_groq_key
supabase functions deploy groq-ai
```

Then configure the app with:

```text
GROQ_PROXY_ENDPOINT=https://YOUR_PROJECT.supabase.co/functions/v1/groq-ai
```

The Flutter app will prefer `GROQ_PROXY_ENDPOINT` when it is configured, and
fall back to direct `GROQ_API_KEY` only for local development.
