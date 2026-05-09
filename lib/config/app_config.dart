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

  static const _voiceTtsEndpointDefine = String.fromEnvironment(
    'VOICE_TTS_ENDPOINT',
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

  static const _cartesiaApiKeyDefine = String.fromEnvironment(
    'CARTESIA_API_KEY',
    defaultValue: 'PASTE_CARTESIA_API_KEY',
  );

  static const _cartesiaVoiceIdDefine = String.fromEnvironment(
    'CARTESIA_VOICE_ID',
    defaultValue: '1259b7e3-cb8a-43df-9446-30971a46b8b0',
  );

  static const _cartesiaModelIdDefine = String.fromEnvironment(
    'CARTESIA_MODEL_ID',
    defaultValue: 'sonic-3',
  );

  static const _cartesiaVersionDefine = String.fromEnvironment(
    'CARTESIA_VERSION',
    defaultValue: '2026-03-01',
  );

  static String get supabaseUrl =>
      _configuredValue('SUPABASE_URL', _supabaseUrlDefine);

  static String get supabaseApiKey =>
      _configuredValue('SUPABASE_API_KEY', _supabaseApiKeyDefine);

  static String get groqApiKey =>
      _configuredValue('GROQ_API_KEY', _groqApiKeyDefine);

  static String get groqProxyEndpoint =>
      _configuredValue('GROQ_PROXY_ENDPOINT', _groqProxyEndpointDefine);

  static String get voiceTtsEndpoint =>
      _configuredValue('VOICE_TTS_ENDPOINT', _voiceTtsEndpointDefine);

  static String get mapTilerKey =>
      _configuredValue('MAPTILER_KEY', _mapTilerKeyDefine);

  static String get dataGovApiKey =>
      _configuredValue('DATA_GOV_API_KEY', _dataGovApiKeyDefine);

  static String get cartesiaApiKey =>
      _configuredValue('CARTESIA_API_KEY', _cartesiaApiKeyDefine);

  static String get cartesiaVoiceId =>
      _configuredValue('CARTESIA_VOICE_ID', _cartesiaVoiceIdDefine);

  static String get cartesiaModelId =>
      _configuredValue('CARTESIA_MODEL_ID', _cartesiaModelIdDefine);

  static String get cartesiaVersion =>
      _configuredValue('CARTESIA_VERSION', _cartesiaVersionDefine);

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseApiKey.isNotEmpty &&
      _hasRealValue(supabaseApiKey);

  static bool get isGroqDirectConfigured => _hasRealValue(groqApiKey);

  static bool get isGroqProxyConfigured =>
      groqProxyEndpoint.startsWith('https://');

  static bool get isGroqConfigured =>
      isGroqDirectConfigured || isGroqProxyConfigured;

  static bool get isVoiceProxyConfigured =>
      voiceTtsEndpoint.startsWith('https://');

  static bool get isCartesiaConfigured =>
      _hasRealValue(cartesiaApiKey) && cartesiaVoiceId.isNotEmpty;

  static bool get isHumanVoiceConfigured =>
      isVoiceProxyConfigured || isCartesiaConfigured;

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
