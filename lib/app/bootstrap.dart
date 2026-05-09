import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dependency_injection.dart';
import 'app.dart';
import 'app_state.dart';

Future<void> bootstrap() async {
  await dotenv.load(fileName: '.env', isOptional: true);
  final graph = await buildDependencyGraph();
  runApp(
    AppStateScope(
      state: graph.state,
      child: KrishiMitraApp(services: graph.services),
    ),
  );
}
