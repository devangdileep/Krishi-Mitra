# Human Voice Setup

Krishi Mitra uses Deepgram Aura for low-latency neural text-to-speech and falls
back to the device TTS engine when Deepgram is not configured or a network
request fails.

## Direct Development Setup

For local testing, add these values to `.env` or pass them with
`--dart-define`:

```powershell
E:\flutter\bin\flutter.bat run `
  --dart-define=DEEPGRAM_API_KEY=YOUR_KEY `
  --dart-define=DEEPGRAM_TTS_MODEL=aura-2-thalia-en
```

The app posts to `https://api.deepgram.com/v1/speak` and expects `audio/mpeg`
bytes. `aura-2-thalia-en` is the default conversational Aura 2 voice.

## Production Guidance

Do not ship a production APK with `DEEPGRAM_API_KEY` compiled into it. Mobile app
binaries can be inspected. For production, proxy TTS through a backend or
Supabase Edge Function and keep the Deepgram key server-side.

## Latency Strategy

The assistant speaks a short local cue while the AI answer is being generated,
then plays the Deepgram response in short chunks. This keeps the interaction
responsive even when the answer takes a moment to prepare.
