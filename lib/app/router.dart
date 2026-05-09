import 'package:go_router/go_router.dart';
import 'app_services.dart';
import '../ui/screens.dart';

GoRouter buildRouter(AppServices services) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(auth: services.auth),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeShell(
          api: services.api,
          repository: services.repository,
          weather: services.weather,
          mandi: services.mandi,
          decisionEngine: services.decisionEngine,
          intelligence: services.intelligence,
          voiceService: services.voiceService,
        ),
      ),
    ],
  );
}
