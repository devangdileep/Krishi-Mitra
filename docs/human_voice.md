# Human Voice Setup

Krishi Mitra uses language-aware text-to-speech:

- English uses Deepgram Aura when `DEEPGRAM_API_KEY` is configured.
- Indian regional languages such as Hindi, Malayalam, Tamil, Telugu, and
  Kannada use Sarvam Bulbul v3 when `SARVAM_API_KEY` is configured. This gives
  studio-quality Indian accents and better regional pronunciation than a generic
  English TTS voice.
- If Sarvam is not configured, Indian languages use the best native Android
  Indian voice installed on the device.
- Deepgram Aura remains available for non-Indian English cloud playback.
- The app falls back to the device TTS engine when cloud playback is not suitable
  or a network request fails.

## Direct Development Setup

For local testing, add these values to `.env` or pass them with
`--dart-define`:

```powershell
E:\flutter\bin\flutter.bat run `
  --dart-define=SARVAM_API_KEY=YOUR_SARVAM_KEY `
  --dart-define=SARVAM_TTS_MODEL=bulbul:v3 `
  --dart-define=SARVAM_TTS_SAMPLE_RATE=24000 `
  --dart-define=DEEPGRAM_API_KEY=YOUR_KEY `
  --dart-define=DEEPGRAM_TTS_MODEL=aura-2-arcas-en
```

For Indian regional languages, the app posts to
`https://api.sarvam.ai/text-to-speech` with `model=bulbul:v3`, decodes the
base64 audio response, and plays MP3 chunks. Default male speaker choices are
language-aware: `ratan` for Tamil, `shubh` for Hindi, Telugu, Kannada,
Malayalam, and Odia, `rehan` for Bengali, and `mani` for Punjabi. Set
`SARVAM_TTS_SPEAKER` only when you want one speaker globally.

Deepgram posts to `https://api.deepgram.com/v1/speak` and expects `audio/mpeg`
bytes when non-Indian English cloud playback is selected.

## Production Guidance

Do not ship a production APK with `SARVAM_API_KEY` or `DEEPGRAM_API_KEY`
compiled into it. Mobile app binaries can be inspected. For production, proxy
TTS through a backend or Supabase Edge Function and keep provider keys
server-side.

## Latency Strategy

The assistant speaks the short thinking cue through the same language-aware voice
engine selected for the answer. Sarvam and Deepgram audio are chunked, fetched
ahead, and cached; native Indian voices use Android's TTS engine directly.
