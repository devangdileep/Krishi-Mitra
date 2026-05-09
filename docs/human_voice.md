# Human Voice Setup

Krishi Mitra now supports a cloud neural voice path with an offline device TTS
fallback.

## Recommended Production Setup

Put the external TTS secret on a backend or Supabase Edge Function and pass only
the endpoint to the app:

```powershell
E:\flutter\bin\flutter.bat run `
  --dart-define=VOICE_TTS_ENDPOINT=https://YOUR_PROJECT.supabase.co/functions/v1/human-voice
```

The endpoint should accept JSON:

```json
{
  "text": "Advice to read aloud",
  "language_code": "hi",
  "voice_id": "JBFqnCBsd6RMkjVDRZzb",
  "model_id": "eleven_multilingual_v2"
}
```

and return `audio/mpeg` bytes.

## Direct Development Setup

For local testing, the app can call ElevenLabs directly:

```powershell
E:\flutter\bin\flutter.bat run `
  --dart-define=ELEVENLABS_API_KEY=YOUR_KEY `
  --dart-define=ELEVENLABS_VOICE_ID=JBFqnCBsd6RMkjVDRZzb `
  --dart-define=ELEVENLABS_MODEL_ID=eleven_v3 `
  --dart-define=ELEVENLABS_FALLBACK_MODEL_ID=eleven_multilingual_v2
```

Do not ship a production APK with `ELEVENLABS_API_KEY` compiled into it. Mobile
app binaries can be inspected, so production voice generation should go through
the secure proxy path.

## Indian Voice Selection

The model controls naturalness. The voice ID controls accent. The app now uses
`eleven_v3` first and falls back to `eleven_multilingual_v2`, but you still need
an Indian-accent voice ID for English responses to sound Indian.

In ElevenLabs, create/restrict a key with:

- Text to Speech: Access
- Voices: Read access, only while selecting a voice

Then search the Voice Library for an Indian English voice and copy its voice ID
into `.env`:

```text
ELEVENLABS_VOICE_ID=your_indian_voice_id
```

After the voice ID is selected, you can remove Voices read permission again.
