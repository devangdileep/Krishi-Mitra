import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_services.dart';
import 'app_state.dart';
import 'router.dart';

class KrishiMitraApp extends StatelessWidget {
  const KrishiMitraApp({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return MaterialApp.router(
      title: 'Krishi Mitra',
      themeMode: state.darkThemeEnabled ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: buildRouter(services),
      debugShowCheckedModeBanner: false,
    );
  }
}
