import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

enum VoiceProvider { deepgram, deviceFallback }

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
  String get voiceStatusLabel {
    if (AppConfig.isDeepgramConfigured) {
      return 'Deepgram Aura voice ready';
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

    if (AppConfig.isDeepgramConfigured) {
      try {
        await _speakCloud(
            prepared, languageCode, _audioFromDeepgram, generation);
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
    try {
      await _speakDevice(prepared, languageCode);
    } catch (_) {
      // A cue is only a latency helper; the main answer still updates on screen.
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
    int generation,
  ) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    for (final chunk in _speechChunks(text, maxChars: 320)) {
      // Bail out if a newer stop() or speak() happened while we were fetching.
      if (_speakGeneration != generation) return;
      final file = await resolveAudio(chunk, languageCode);
      if (_speakGeneration != generation) return;
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
            '$namespace|$languageCode|${AppConfig.deepgramTtsModel}|'
            '${modelId ?? AppConfig.deepgramTtsModel}|$text',
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
    await _fallbackTts.setPitch(1.04);
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

      // Indian locale markers — these indicate an Indian-sounding accent.
      if (locale.endsWith('-in') || locale.contains('_in')) score += 80;
      if (locale.contains('ind') || locale.contains('india')) score += 80;

      // Name-based Indian indicators (Samsung/Google often label these)
      if (name.contains('india') || name.contains('indian')) score += 90;
      if (name.contains('hindi') && baseLanguage == 'hi') score += 60;
      if (name.contains('tamil') && baseLanguage == 'ta') score += 60;
      if (name.contains('telugu') && baseLanguage == 'te') score += 60;
      if (name.contains('malayalam') && baseLanguage == 'ml') score += 60;
      if (name.contains('kannada') && baseLanguage == 'kn') score += 60;

      // Prefer female voices — they tend to sound more natural on mobile TTS.
      if (name.contains('female') || name.contains('woman')) score += 15;

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
