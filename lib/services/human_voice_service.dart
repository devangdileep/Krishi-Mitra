import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

enum VoiceProvider { sarvam, deepgram, deviceFallback }

class VoicePlaybackResult {
  const VoicePlaybackResult({
    required this.provider,
    this.message,
  });

  final VoiceProvider provider;
  final String? message;

  bool get usedCloud => provider != VoiceProvider.deviceFallback;
}

class HumanVoiceService {
  HumanVoiceService({http.Client? client, AudioPlayer? player, FlutterTts? tts})
      : _client = client ?? http.Client(),
        _player = player ?? AudioPlayer(),
        _fallbackTts = tts ?? FlutterTts();

  final http.Client _client;
  final AudioPlayer _player;
  final FlutterTts _fallbackTts;

  /// Incremented on every stop() or new speak() call. Any in-flight playback
  /// loop whose captured generation no longer matches will bail out, preventing
  /// audio from overlapping across screens.
  int _speakGeneration = 0;

  bool get isPlaying => _speakGeneration > 0;
  bool get cloudVoiceReady => AppConfig.isHumanVoiceConfigured;

  bool usesCloudVoiceFor(String languageCode) =>
      _usesSarvamVoiceFor(languageCode) || _usesDeepgramVoiceFor(languageCode);

  bool usesNativeIndianVoiceFor(String languageCode) =>
      !_usesSarvamVoiceFor(languageCode) &&
      _prefersNativeIndianTts(languageCode);

  String get voiceStatusLabel {
    if (AppConfig.isSarvamConfigured) {
      return 'Sarvam Indian studio voice ready';
    }
    if (AppConfig.isDeepgramConfigured) {
      return 'Deepgram Aura voice available';
    }
    return 'Offline device voice';
  }

  String voiceStatusLabelFor(String languageCode) {
    if (_usesSarvamVoiceFor(languageCode)) {
      return 'Sarvam ${_spokenLanguageName(languageCode)} studio voice';
    }
    if (_usesDeepgramVoiceFor(languageCode)) {
      return 'Deepgram Aura voice';
    }
    if (_prefersNativeIndianTts(languageCode)) {
      return 'Native ${_spokenLanguageName(languageCode)} voice';
    }
    return 'Offline device voice';
  }

  Future<VoicePlaybackResult> speak(
    String text,
    String languageCode, {
    String? contextLabel,
  }) async {
    final prepared = _prepareForSpeech(text, contextLabel: contextLabel);
    if (prepared.isEmpty) {
      return const VoicePlaybackResult(
        provider: VoiceProvider.deviceFallback,
        message: 'Nothing to speak.',
      );
    }

    // Cancel any in-flight playback and hard-stop both engines.
    await stop();

    // Capture the current generation so the playback loop can detect
    // cancellation between chunks.
    final generation = _speakGeneration;

    if (_usesSarvamVoiceFor(languageCode)) {
      try {
        await _speakCloud(
          prepared,
          languageCode,
          _audioFromSarvam,
          generation,
          maxChars: 420,
        );
        return const VoicePlaybackResult(provider: VoiceProvider.sarvam);
      } catch (error) {
        if (_speakGeneration != generation) {
          return const VoicePlaybackResult(
            provider: VoiceProvider.deviceFallback,
            message: 'Playback cancelled.',
          );
        }
        return _fallback(prepared, languageCode, error, generation);
      }
    }

    if (_usesDeepgramVoiceFor(languageCode)) {
      try {
        await _speakCloud(
          prepared,
          languageCode,
          _audioFromDeepgram,
          generation,
        );
        return const VoicePlaybackResult(provider: VoiceProvider.deepgram);
      } catch (error) {
        if (_speakGeneration != generation) {
          return const VoicePlaybackResult(
            provider: VoiceProvider.deviceFallback,
            message: 'Playback cancelled.',
          );
        }
        return _fallback(prepared, languageCode, error, generation);
      }
    }

    await _speakDevice(prepared, languageCode);
    return const VoicePlaybackResult(provider: VoiceProvider.deviceFallback);
  }

  Future<void> stop() async {
    // Bump generation so any in-flight loop sees the mismatch and exits.
    _speakGeneration++;
    await _player.stop();
    await _fallbackTts.stop();
  }

  Future<void> speakLocalCue(String text, String languageCode) async {
    final prepared = _prepareForSpeech(text);
    if (prepared.isEmpty) return;
    await stop();
    final generation = _speakGeneration;
    try {
      if (_usesSarvamVoiceFor(languageCode)) {
        await _speakCloud(
          prepared,
          languageCode,
          _audioFromSarvam,
          generation,
          maxChars: 180,
        );
        return;
      }
      if (_usesDeepgramVoiceFor(languageCode)) {
        await _speakCloud(
          prepared,
          languageCode,
          _audioFromDeepgram,
          generation,
          maxChars: 180,
        );
        return;
      }
      await _speakDevice(prepared, languageCode);
    } catch (_) {
      if (_speakGeneration != generation) return;
      try {
        await _speakDevice(prepared, languageCode);
      } catch (_) {
        // A cue is only a latency helper; the main answer still updates on screen.
      }
    }
  }

  Future<VoicePlaybackResult> _fallback(
    String text,
    String languageCode,
    Object error,
    int generation,
  ) async {
    if (_speakGeneration != generation) {
      return const VoicePlaybackResult(
        provider: VoiceProvider.deviceFallback,
        message: 'Playback cancelled.',
      );
    }
    try {
      await _speakDevice(text, languageCode);
    } catch (deviceError) {
      return VoicePlaybackResult(
        provider: VoiceProvider.deviceFallback,
        message:
            'Voice playback failed. Cloud voice error: $error. Device voice error: $deviceError',
      );
    }
    return VoicePlaybackResult(
      provider: VoiceProvider.deviceFallback,
      message: 'Cloud voice failed, used offline voice. $error',
    );
  }

  Future<void> _speakCloud(
    String text,
    String languageCode,
    Future<File> Function(String chunk, String languageCode) resolveAudio,
    int generation, {
    int maxChars = 260,
  }) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    final chunks = _speechChunks(text, maxChars: maxChars);
    Future<File>? nextAudio =
        chunks.isEmpty ? null : resolveAudio(chunks.first, languageCode);
    for (var index = 0; index < chunks.length; index++) {
      if (_speakGeneration != generation) return;
      final pendingAudio = nextAudio;
      if (pendingAudio == null) return;
      final file = await pendingAudio;
      if (_speakGeneration != generation) return;
      nextAudio = index + 1 < chunks.length
          ? resolveAudio(chunks[index + 1], languageCode)
          : null;
      final completed = _player.onPlayerComplete.first.timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Cloud audio playback timed out.');
        },
      );
      await _player.play(DeviceFileSource(file.path));
      await completed;
      if (_speakGeneration != generation) return;
    }
  }

  Future<File> _audioFromSarvam(String text, String languageCode) async {
    final model = AppConfig.sarvamTtsModel;
    final targetLanguage = _sarvamLanguageCode(languageCode);
    final speaker = _sarvamSpeakerFor(targetLanguage);
    final sampleRate = AppConfig.sarvamTtsSampleRate;
    return _cachedAudioFile(
      namespace: 'sarvam',
      text: text,
      languageCode: targetLanguage,
      modelId: '$model|$speaker|$sampleRate',
      extension: 'mp3',
      fetch: () => _postSarvamAudio(
        text: text,
        targetLanguageCode: targetLanguage,
        model: model,
        speaker: speaker,
        sampleRate: sampleRate,
      ),
    );
  }

  Future<File> _audioFromDeepgram(String text, String languageCode) async {
    final model = AppConfig.deepgramTtsModel;
    return _cachedAudioFile(
      namespace: 'deepgram',
      text: text,
      languageCode: _shortLanguageCode(languageCode),
      modelId: model,
      extension: 'mp3',
      fetch: () => _postAudio(
        Uri.https('api.deepgram.com', '/v1/speak', {
          'model': model,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
          'Authorization': 'Token ${AppConfig.deepgramApiKey}',
        },
        body: {
          'text': _naturalizeForIndianFarmers(text, languageCode),
        },
      ),
    );
  }

  Future<List<int>> _postSarvamAudio({
    required String text,
    required String targetLanguageCode,
    required String model,
    required String speaker,
    required int sampleRate,
  }) async {
    final response = await _client
        .post(
          Uri.https('api.sarvam.ai', '/text-to-speech'),
          headers: {
            'Content-Type': 'application/json',
            'api-subscription-key': AppConfig.sarvamApiKey,
          },
          body: jsonEncode({
            'text': text,
            'target_language_code': targetLanguageCode,
            'model': model,
            'speaker': speaker,
            'pace': 1.02,
            'speech_sample_rate': sampleRate,
            'output_audio_codec': 'mp3',
            'temperature': 0.45,
          }),
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Sarvam TTS HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final audios = decoded['audios'];
    if (audios is! List || audios.isEmpty || audios.first is! String) {
      throw StateError('Sarvam TTS returned no audio.');
    }
    return base64Decode(audios.first as String);
  }

  Future<List<int>> _postAudio(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw StateError('TTS HTTP ${response.statusCode}: ${response.body}');
  }

  Future<File> _cachedAudioFile({
    required String namespace,
    required String text,
    required String languageCode,
    String? modelId,
    String extension = 'mp3',
    required Future<List<int>> Function() fetch,
  }) async {
    final cacheDir = Directory(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}krishi_voice_cache',
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final cacheKey = sha256
        .convert(
          utf8.encode(
            '$namespace|$languageCode|${modelId ?? ''}|$text',
          ),
        )
        .toString();
    final file =
        File('${cacheDir.path}${Platform.pathSeparator}$cacheKey.$extension');
    if (await file.exists() && await file.length() > 1024) return file;

    final bytes = await fetch();
    if (bytes.length < 1024) {
      throw StateError('TTS returned an empty audio payload.');
    }
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _speakDevice(String text, String languageCode) async {
    await _fallbackTts.awaitSpeakCompletion(true);
    await _selectBestDeviceVoice(languageCode);
    await _fallbackTts.setSpeechRate(_fallbackRate(languageCode));
    await _fallbackTts.setPitch(0.96);
    await _fallbackTts.setVolume(1.0);
    for (final chunk in _speechChunks(text, maxChars: 750)) {
      await _fallbackTts.speak(chunk);
    }
  }

  double _fallbackRate(String languageCode) {
    if (languageCode.startsWith('en')) return 0.44;
    if (languageCode.startsWith('hi')) return 0.42;
    return 0.40;
  }

  String _shortLanguageCode(String languageCode) =>
      languageCode.split('-').first.toLowerCase();

  bool _prefersNativeIndianTts(String languageCode) {
    final normalized = languageCode.toLowerCase();
    final baseLanguage = _shortLanguageCode(normalized);
    const indianLanguages = {
      'hi',
      'ml',
      'ta',
      'te',
      'kn',
      'mr',
      'bn',
      'gu',
      'pa',
      'or',
      'ur',
    };
    if (baseLanguage == 'en') {
      return normalized.endsWith('-in') || normalized.contains('_in');
    }
    return normalized.endsWith('-in') || indianLanguages.contains(baseLanguage);
  }

  bool _usesSarvamVoiceFor(String languageCode) =>
      AppConfig.isSarvamConfigured &&
      _shortLanguageCode(languageCode) != 'en' &&
      _sarvamSupportedLanguages.contains(_sarvamLanguageCode(languageCode));

  bool _usesDeepgramVoiceFor(String languageCode) =>
      AppConfig.isDeepgramConfigured &&
      _shortLanguageCode(languageCode) == 'en';

  static const _sarvamSupportedLanguages = {
    'hi-IN',
    'bn-IN',
    'ta-IN',
    'te-IN',
    'kn-IN',
    'ml-IN',
    'mr-IN',
    'gu-IN',
    'pa-IN',
    'od-IN',
  };

  String _sarvamLanguageCode(String languageCode) {
    final normalized = languageCode.replaceAll('_', '-');
    final base = _shortLanguageCode(normalized);
    switch (base) {
      case 'en':
        return normalized.toLowerCase().endsWith('-in') ? 'en-IN' : normalized;
      case 'hi':
        return 'hi-IN';
      case 'bn':
        return 'bn-IN';
      case 'ta':
        return 'ta-IN';
      case 'te':
        return 'te-IN';
      case 'kn':
        return 'kn-IN';
      case 'ml':
        return 'ml-IN';
      case 'mr':
        return 'mr-IN';
      case 'gu':
        return 'gu-IN';
      case 'pa':
        return 'pa-IN';
      case 'od':
      case 'or':
        return 'od-IN';
      default:
        return normalized;
    }
  }

  String _sarvamSpeakerFor(String targetLanguageCode) {
    final configured = AppConfig.sarvamTtsSpeaker.trim().toLowerCase();
    if (configured.isNotEmpty) return configured;
    switch (targetLanguageCode) {
      case 'en-IN':
      case 'ta-IN':
      case 'mr-IN':
      case 'gu-IN':
        return 'ratan';
      case 'bn-IN':
        return 'rehan';
      case 'pa-IN':
        return 'mani';
      case 'hi-IN':
      case 'te-IN':
      case 'kn-IN':
      case 'ml-IN':
      case 'od-IN':
      default:
        return 'shubh';
    }
  }

  String _spokenLanguageName(String languageCode) {
    switch (_shortLanguageCode(languageCode)) {
      case 'en':
        return 'Indian English';
      case 'hi':
        return 'Hindi';
      case 'ml':
        return 'Malayalam';
      case 'ta':
        return 'Tamil';
      case 'te':
        return 'Telugu';
      case 'kn':
        return 'Kannada';
      case 'mr':
        return 'Marathi';
      case 'bn':
        return 'Bengali';
      case 'gu':
        return 'Gujarati';
      case 'pa':
        return 'Punjabi';
      case 'or':
        return 'Odia';
      case 'ur':
        return 'Urdu';
      default:
        return 'device';
    }
  }

  String _naturalizeForIndianFarmers(String text, String languageCode) {
    if (!languageCode.startsWith('en')) return text;
    return text
        .replaceAll('Krishi Mitra', 'Krishi Mitra')
        .replaceAll('irrigation', 'irrigation')
        .replaceAll('fertilizer', 'fertilizer');
  }

  Future<void> _selectBestDeviceVoice(String languageCode) async {
    await _fallbackTts.setLanguage(languageCode);
    final voices = await _fallbackTts.getVoices;
    if (voices is! List) return;

    final normalizedLanguage = languageCode.toLowerCase();
    final baseLanguage = normalizedLanguage.split('-').first;
    Map<dynamic, dynamic>? best;
    var bestScore = -1;
    for (final voice in voices.whereType<Map>()) {
      final locale = '${voice['locale'] ?? ''}'.toLowerCase();
      final name = '${voice['name'] ?? ''}'.toLowerCase();
      var score = 0;

      // Exact locale match (e.g. hi-in matches hi-in)
      if (locale == normalizedLanguage) score += 80;
      // Same base language (e.g. hi-* when we want hi-in)
      if (locale.startsWith('$baseLanguage-')) score += 35;

      // Indian locale markers indicate an Indian-sounding accent.
      if (locale.endsWith('-in') || locale.contains('_in')) score += 80;
      if (locale.contains('ind') || locale.contains('india')) score += 80;

      // Name-based Indian indicators (Samsung/Google often label these)
      if (name.contains('india') || name.contains('indian')) score += 90;
      if (name.contains('hindi') && baseLanguage == 'hi') score += 60;
      if (name.contains('tamil') && baseLanguage == 'ta') score += 60;
      if (name.contains('telugu') && baseLanguage == 'te') score += 60;
      if (name.contains('malayalam') && baseLanguage == 'ml') score += 60;
      if (name.contains('kannada') && baseLanguage == 'kn') score += 60;

      // Prefer a male fallback when Deepgram is unavailable.
      if (name.contains('male') ||
          name.contains('man') ||
          name.contains('masculine')) {
        score += 28;
      }
      if (name.contains('female') ||
          name.contains('woman') ||
          name.contains('feminine')) {
        score -= 20;
      }

      // Prefer higher-quality engine voices.
      if (name.contains('google')) score += 18;
      if (name.contains('neural') || name.contains('wavenet')) score += 22;
      if (name.contains('samsung')) score += 12;
      if (name.contains('enhanced')) score += 16;

      if (score > bestScore) {
        bestScore = score;
        best = voice;
      }
    }

    if (best == null || bestScore < 35) return;
    final name = best['name'];
    final locale = best['locale'];
    if (name is String && locale is String) {
      await _fallbackTts.setVoice({'name': name, 'locale': locale});
    }
  }

  String _prepareForSpeech(String text, {String? contextLabel}) {
    final cleaned = text
        .replaceAll(RegExp(r'[*_`#>\[\]{}]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' C', ' degrees Celsius')
        .replaceAll(' ha', ' hectares')
        .trim();
    if (cleaned.isEmpty) return cleaned;
    final prefix = contextLabel == null || contextLabel.trim().isEmpty
        ? ''
        : '${contextLabel.trim()}. ';
    return '$prefix$cleaned';
  }

  List<String> _speechChunks(String text, {required int maxChars}) {
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((sentence) => sentence.trim().isNotEmpty);
    final chunks = <String>[];
    final buffer = StringBuffer();

    for (final sentence in sentences) {
      final candidate = sentence.trim();
      if (candidate.length > maxChars) {
        if (buffer.isNotEmpty) {
          chunks.add(buffer.toString().trim());
          buffer.clear();
        }
        for (var start = 0; start < candidate.length; start += maxChars) {
          chunks.add(candidate.substring(
            start,
            (start + maxChars).clamp(0, candidate.length).toInt(),
          ));
        }
        continue;
      }
      if (buffer.length + candidate.length + 1 > maxChars) {
        chunks.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.write(candidate);
      buffer.write(' ');
    }

    if (buffer.isNotEmpty) chunks.add(buffer.toString().trim());
    return chunks;
  }
}
