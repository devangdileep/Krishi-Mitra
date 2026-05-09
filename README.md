<div align="center">
  <h1>🌾 Krishi Mitra</h1>
  <h3>Your AI-Powered Agricultural Companion</h3>
  <br />
  <p>
    An offline-first mobile app built with Flutter. Krishi Mitra empowers farmers with hyper-local agronomic intelligence, precision farming tools, and voice-assisted decision-making.
  </p>
  <br />
  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white" alt="Dart" /></a>
    <a href="https://supabase.com/"><img src="https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white" alt="Supabase" /></a>
    <img src="https://img.shields.io/badge/Groq_AI-F55036?style=flat" alt="Groq" />
  </p>
</div>

---

## ✨ Key Features

*   🌍 **Offline-First Architecture**: Seamlessly syncs farmland data, crops, and AI reports using an optimistic save queue backed by Supabase.
*   🗺️ **Precision Farmland Mapping**: Replaced standard maps with hardware-accelerated **MapLibre GL**. Includes a unique "Walk-the-Boundary" GPS streaming feature with jitter-filtering to map farm borders on foot.
*   🧠 **Crop Intelligence Engine**: Query any crop to instantly receive AI-generated insights regarding suitable regions, harvesting timelines, and estimated ROI/Market Prices.
*   🚜 **Personalized Suitability AI**: The AI dynamically analyzes your mapped farmlands (soil pH, terrain type, irrigation method) to recommend the best crops for your exact geography.
*   🎙️ **Conversational Voice Assistant**: Multi-lingual voice support (English, Hindi, Malayalam, Tamil) utilizing `speech_to_text` and real-time TTS via Cartesia/ElevenLabs.
*   🌤️ **Hyper-Local Weather**: Integrated with Open-Meteo to provide 7-day weather forecasts that directly influence the AI's smart action window recommendations (e.g., delaying irrigation if rain is expected).
*   💎 **Premium Glassmorphism UI**: Beautifully designed responsive interface featuring dynamic blur effects, sleek micro-animations, and a unified design system.

## 🛠️ Technology Stack

*   **Frontend**: Flutter (Dart)
*   **Backend / Database**: Supabase (PostgreSQL, Auth, Edge Functions)
*   **AI Engine**: Groq API (Running `llama-3.3-70b-versatile` & `llama-3.1-8b-instant`)
*   **Geospatial / Maps**: MapLibre GL, Geolocator
*   **Weather API**: Open-Meteo (Free, No Auth Required)
*   **TTS Integration**: Cartesia / ElevenLabs
*   **State Management**: InheritedNotifier (Native Flutter) & `app_state.dart`

---

## 🚀 Getting Started

### 1. Environment Setup

Krishi Mitra uses `flutter_dotenv` to securely load API keys. **No API keys are hardcoded into the project**.

Create a `.env` file in the root directory of the project:

```env
# Database
SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL
SUPABASE_API_KEY=YOUR_SUPABASE_ANON_KEY

# Artificial Intelligence (Core)
GROQ_API_KEY=YOUR_GROQ_API_KEY
GROQ_PROXY_ENDPOINT= # Optional: Edge Function URL for production

# Text-to-Speech (Optional)
CARTESIA_API_KEY=YOUR_CARTESIA_API_KEY
CARTESIA_VOICE_ID=1259b7e3-cb8a-43df-9446-30971a46b8b0
CARTESIA_MODEL_ID=sonic-3
CARTESIA_VERSION=2026-03-01

# Real-Time Agricultural Data (Optional)
DATA_GOV_API_KEY=YOUR_DATA_GOV_KEY
```

### 2. Installation & Run

1.  Ensure you have the Flutter SDK installed.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application on an emulator or physical device:
    ```bash
    flutter run
    ```

---

## 🔒 Security & Best Practices

*   **API Security**: Ensure that the `.env` file is never committed to version control. It is currently added to `.gitignore`.
*   **Production Deployment**: For production, do NOT ship the `GROQ_API_KEY` inside the mobile binary. Instead, utilize the implemented `GROQ_PROXY_ENDPOINT` logic in `app_config.dart` to route AI requests through a secure Supabase Edge Function.
*   **Data Synchronization**: Local storage currently utilizes `SharedPreferences` for fast, lightweight JSON caching. If the dataset scales significantly, migrating to `Drift` or `Isar` is recommended.

## 📜 License
This project is open-source and available under the [MIT License](LICENSE).
