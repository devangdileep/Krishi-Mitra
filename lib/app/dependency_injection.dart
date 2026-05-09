import '../services/ai_services.dart';
import '../services/api_clients.dart';
import '../services/auth_service.dart';
import '../services/human_voice_service.dart';
import '../services/local_store.dart';
import 'app_services.dart';
import 'app_state.dart';

class AppDependencyGraph {
  const AppDependencyGraph({
    required this.state,
    required this.services,
  });

  final AppState state;
  final AppServices services;
}

Future<AppDependencyGraph> buildDependencyGraph() async {
  final store = await LocalStore.create();
  final state = AppState(store);
  final api = SupabaseRestClient();
  final repository = FarmlandRepository(api, store);

  return AppDependencyGraph(
    state: state,
    services: AppServices(
      api: api,
      auth: AuthService(api),
      repository: repository,
      weather: WeatherClient(),
      mandi: DataGovMandiClient(),
      decisionEngine: DecisionEngine(),
      intelligence: FarmlandIntelligence(store),
      voiceService: HumanVoiceService(),
    ),
  );
}
