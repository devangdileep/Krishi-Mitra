# Krishi Mitra

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white)](https://supabase.com/)
[![Groq](https://img.shields.io/badge/Groq-AI-F55036?style=flat)](https://groq.com/)
[![MapLibre](https://img.shields.io/badge/MapLibre-Maps-396CB2?style=flat)](https://maplibre.org/)

Krishi Mitra is an offline-first AI farming platform for field mapping, crop
planning, mandi-aware market decisions, weather risk assessment, and
voice-assisted farm guidance.

The app is designed for Indian farming workflows: farmers can map farmland,
record crop and soil details, compare crop suitability, receive AI agronomy
reports, check government mandi price signals, and speak with an assistant in
English or Indian regional languages.

## Table Of Contents

- [Highlights](#highlights)
- [Product Capabilities](#product-capabilities)
- [AI And Voice System](#ai-and-voice-system)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Environment Variables](#environment-variables)
- [Local Development](#local-development)
- [Android Build](#android-build)
- [Repository Structure](#repository-structure)
- [Security Notes](#security-notes)
- [Documentation](#documentation)

## Highlights

- Offline-first Flutter app with local caching and Supabase-backed sync.
- MapLibre GL farmland mapping with GPS-assisted field boundary capture.
- Crop coverage tracking with advanced farm metadata for better AI reports.
- Location-aware crop advisor using farmland, weather, and mandi context.
- AI sustainability reports with risks, smart action windows, and practical
  agronomy guidance.
- Voice assistant that answers using saved farm profiles, weather, crop data,
  and market context.
- Deepgram Aura for English voice output.
- Sarvam Bulbul v3 for Indian regional language studio voices.
- Android TTS fallback when cloud audio is unavailable.
- data.gov.in AGMARKNET integration for mandi price intelligence.
- Open-Meteo integration for hyper-local weather forecasts.

## Product Capabilities

| Area | Capability |
| --- | --- |
| Farm management | Create, edit, delete, and sync farmland records. |
| Mapping | Capture farm boundaries with MapLibre GL and GPS-assisted workflows. |
| Crop planning | Track crop coverage, growth stage, variety, and sowing date. |
| Advanced farm profile | Store soil type, pH, terrain, irrigation, water source, ownership, previous crop, market, elevation, and farm age. |
| Crop advisor | Search crops and compare suitability against saved farmland and local weather. |
| AI reports | Generate farm-specific sustainability reports, risks, yield timelines, and expert suggestions. |
| Voice assistant | Ask farm questions naturally and receive context-aware spoken answers. |
| Weather | Use Open-Meteo forecasts for rain, temperature, and risk timing. |
| Market intelligence | Use data.gov.in mandi rows for price benchmarks, opportunity comparison, and buyer offer checks. |
| Profile | Manage user profile, language, and default location for local recommendations. |

## AI And Voice System

The assistant is built to answer farm questions with field-specific context
instead of generic chatbot responses.

When available, the prompt includes:

- User profile location and GPS coordinates.
- Saved farmlands and mapped area.
- Soil type, pH, terrain, irrigation, and water source.
- Current crops, coverage percentage, growth stage, variety, and sowing date.
- Previous crop and nearest market.
- Open-Meteo weather summary.
- data.gov.in mandi records for crops mentioned in the question.

### Voice Routing

| Language group | Provider | Purpose |
| --- | --- | --- |
| English | Deepgram Aura | Low-latency English cloud voice. |
| Hindi, Malayalam, Tamil, Telugu, Kannada, Bengali, Marathi, Gujarati, Punjabi, Odia | Sarvam Bulbul v3 | Studio-quality Indian regional voices. |
| Any unsupported or failed cloud route | Android device TTS | Offline fallback. |

Sarvam speaker selection is language-aware by default. Leave
`SARVAM_TTS_SPEAKER` empty unless a single global speaker is required.

## Technology Stack

| Layer | Technology |
| --- | --- |
| Mobile app | Flutter, Dart |
| Navigation/state | GoRouter, InheritedNotifier, local app state |
| Backend/data | Supabase REST, local SharedPreferences cache |
| AI | Groq chat completions |
| Voice input | `speech_to_text` |
| Voice output | Deepgram Aura, Sarvam Bulbul v3, Android TTS fallback |
| Maps/location | MapLibre GL, Geolocator |
| Weather | Open-Meteo |
| Market prices | data.gov.in AGMARKNET API |
| Audio playback | `audioplayers` |
| Configuration | `flutter_dotenv`, dart-defines |

## Architecture

```text
Flutter UI
  |
  |-- app/
  |     App state, routing, dependency injection
  |
  |-- ui/
  |     Screens, navigation shell, voice assistant, farm/report/market/profile UI
  |
  |-- services/
  |     Supabase REST, Groq AI, weather, mandi data, human voice service
  |
  |-- models/
  |     Farm, crop, weather, report, mandi, marketplace, and user models
  |
  |-- config/
        Runtime configuration from .env and dart-defines
```

The app keeps user-facing workflows responsive with local cached data first, then
refreshes remote data when network access is available.

## Environment Variables

Create a `.env` file in the project root. Do not commit real keys.

```env
# Supabase
SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL
SUPABASE_API_KEY=YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY

# Groq AI
GROQ_API_KEY=YOUR_GROQ_API_KEY
GROQ_PROXY_ENDPOINT=

# Maps
MAPTILER_KEY=YOUR_MAPTILER_KEY

# Government mandi data
DATA_GOV_API_KEY=YOUR_DATA_GOV_API_KEY

# English cloud voice
DEEPGRAM_API_KEY=YOUR_DEEPGRAM_API_KEY
DEEPGRAM_TTS_MODEL=aura-2-arcas-en

# Indian regional cloud voice
SARVAM_API_KEY=YOUR_SARVAM_API_KEY
SARVAM_TTS_MODEL=bulbul:v3
SARVAM_TTS_SPEAKER=
SARVAM_TTS_SAMPLE_RATE=24000
```

Notes:

- `GROQ_PROXY_ENDPOINT` is optional in development and recommended in
  production.
- `SARVAM_TTS_SPEAKER` can be left empty for language-specific defaults.
- Android Gradle builds read `.env` and forward supported values into Flutter as
  dart-defines for local development.
- Real keys should never be placed in tracked files.

## Local Development

Install dependencies:

```bash
flutter pub get
```

Run on an emulator or physical device:

```bash
flutter run
```

On Windows, the helper script loads `.env` and passes the required dart-defines:

```powershell
.\tools\run_dev.ps1
```

## Android Build

Build a debug APK:

```powershell
cd android
.\gradlew.bat :app:assembleDebug --no-daemon
```

The Android project currently uses the Gradle wrapper configured for Gradle
9.4.1.

## Repository Structure

```text
android/        Android host project and Gradle configuration
docs/           Architecture, production, AI, voice, and migration notes
lib/app/        App bootstrap, routing, services container, and app state
lib/config/     Runtime app configuration
lib/models/     Data models and JSON mapping
lib/services/   API clients, AI services, auth, local store, and voice service
lib/ui/         Primary Flutter screens and widgets
tools/          Development helper scripts
```

## Security Notes

- Keep `.env` out of version control.
- Do not ship production mobile binaries with direct Groq, Sarvam, Deepgram, or
  Supabase service keys embedded.
- Use Supabase Edge Functions or another backend proxy for production AI and TTS
  orchestration.
- Restrict provider API keys by environment wherever the provider supports it.
- Treat mandi, weather, and AI outputs as decision support, not a replacement
  for local extension officers, soil tests, labels, and verified local advice.

## Documentation

- [Architecture notes](docs/architecture.md)
- [Human voice setup](docs/human_voice.md)
- [Groq AI setup](docs/groq_ai.md)
- [Offline sync architecture](docs/offline-sync-architecture.md)
- [Production readiness report](docs/production-readiness-report.md)

## License

No license file is currently included. Add a license before public distribution
or external reuse.
