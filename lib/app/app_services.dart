import '../services/ai_services.dart';
import '../services/api_clients.dart';
import '../services/auth_service.dart';
import '../services/human_voice_service.dart';

class AppServices {
  const AppServices({
    required this.api,
    required this.auth,
    required this.repository,
    required this.weather,
    required this.mandi,
    required this.decisionEngine,
    required this.intelligence,
    required this.voiceService,
  });

  final SupabaseRestClient api;
  final AuthService auth;
  final FarmlandRepository repository;
  final WeatherClient weather;
  final DataGovMandiClient mandi;
  final DecisionEngine decisionEngine;
  final FarmlandIntelligence intelligence;
  final HumanVoiceService voiceService;
}
