# Krishi Mitra Architecture

Krishi Mitra is being moved toward feature-first clean architecture.

## Current App Layer

- `lib/main.dart` is intentionally tiny and only calls `bootstrap()`.
- `lib/app/bootstrap.dart` owns app startup and root providers.
- `lib/app/dependency_injection.dart` builds the dependency graph.
- `lib/app/router.dart` owns navigation and route transitions.
- `lib/app/app.dart` owns `MaterialApp.router`, theme mode, and app shell wiring.

This keeps startup, dependency creation, navigation, and rendering concerns separated.

## Migration Direction

The existing screens and services will be split gradually into:

- `core/` for config, errors, network, storage, theme, performance, and reusable widgets.
- `features/` for auth, dashboard, farms, maps, crops, reports, alerts, assistant, and profile.
- `shared/` for cross-feature models, repositories, providers, and design-system tokens.

## Engineering Rules

- UI does not own API details.
- Repositories own data access and offline-first behavior.
- Services own external systems such as Groq, ElevenLabs, weather, and Supabase REST.
- App layer owns routing, dependency injection, bootstrap, and global theme state.
- Heavy UI files should be split into feature widgets over time.

## Next Refactor Targets

1. Split `lib/ui/screens.dart` into feature presentation modules.
2. Move `AppConfig` under `core/config`.
3. Move `AppTheme`, `UiPerformance`, and glass components under `core/theme` and `shared/design_system`.
4. Introduce typed failure/result models under `core/errors`.
5. Introduce repository tests with mocked API/local store dependencies.
