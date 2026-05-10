import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const _supabaseUrlDefine = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'PASTE_SUPABASE_URL',
  );

  static const _supabaseApiKeyDefine = String.fromEnvironment(
    'SUPABASE_API_KEY',
    defaultValue: 'PASTE_SUPABASE_API_KEY',
  );

  static const _groqApiKeyDefine = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'PASTE_GROQ_API_KEY',
  );

  static const _groqProxyEndpointDefine = String.fromEnvironment(
    'GROQ_PROXY_ENDPOINT',
    defaultValue: '',
  );

  static const _mapTilerKeyDefine = String.fromEnvironment(
    'MAPTILER_KEY',
    defaultValue: '',
  );

  static const _dataGovApiKeyDefine = String.fromEnvironment(
    'DATA_GOV_API_KEY',
    defaultValue: 'PASTE_DATA_GOV_API_KEY',
  );

  static const _deepgramApiKeyDefine = String.fromEnvironment(
    'DEEPGRAM_API_KEY',
    defaultValue: 'PASTE_DEEPGRAM_API_KEY',
  );

  static const _deepgramTtsModelDefine = String.fromEnvironment(
    'DEEPGRAM_TTS_MODEL',
    defaultValue: 'aura-2-thalia-en',
  );

  static String get supabaseUrl =>
      _configuredValue('SUPABASE_URL', _supabaseUrlDefine);

  static String get supabaseApiKey =>
      _configuredValue('SUPABASE_API_KEY', _supabaseApiKeyDefine);

  static String get groqApiKey =>
      _configuredValue('GROQ_API_KEY', _groqApiKeyDefine);

  static String get groqProxyEndpoint =>
      _configuredValue('GROQ_PROXY_ENDPOINT', _groqProxyEndpointDefine);

  static String get mapTilerKey =>
      _configuredValue('MAPTILER_KEY', _mapTilerKeyDefine);

  static String get dataGovApiKey =>
      _configuredValue('DATA_GOV_API_KEY', _dataGovApiKeyDefine);

  static String get deepgramApiKey =>
      _configuredValue('DEEPGRAM_API_KEY', _deepgramApiKeyDefine);

  static String get deepgramTtsModel =>
      _configuredValue('DEEPGRAM_TTS_MODEL', _deepgramTtsModelDefine);

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseApiKey.isNotEmpty &&
      _hasRealValue(supabaseApiKey);

  static bool get isGroqDirectConfigured => _hasRealValue(groqApiKey);

  static bool get isGroqProxyConfigured =>
      groqProxyEndpoint.startsWith('https://');

  static bool get isGroqConfigured =>
      isGroqDirectConfigured || isGroqProxyConfigured;

  static bool get isDeepgramConfigured => _hasRealValue(deepgramApiKey);

  static bool get isHumanVoiceConfigured => isDeepgramConfigured;

  static String _configuredValue(String key, String dartDefineValue) {
    final envValue = dotenv.isInitialized ? dotenv.maybeGet(key)?.trim() : null;
    if (envValue != null && _hasRealValue(envValue)) return envValue;
    return dartDefineValue.trim();
  }

  static bool _hasRealValue(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('PASTE_') &&
        !trimmed.startsWith('your_');
  }
}
