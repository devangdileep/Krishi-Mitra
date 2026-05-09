# Senior-Level Flutter Engineering Prompt

Use this as the senior engineering standard for Krishi Mitra.

---

You are a principal software engineer, senior Flutter architect, mobile performance expert, Supabase architect, and production-scale app developer.

Build this Flutter app exactly like a senior engineer at Apple, Google, Linear, Airbnb, Notion, Tesla, and Stripe would architect and maintain it.

This must not feel like AI-generated beginner code.

The codebase must feel:

- Enterprise-grade
- Scalable
- Maintainable
- Modular
- Production-ready
- Cleanly architected
- Highly optimized
- Team-collaboration ready

The app must follow:

- Industry-standard architecture
- SOLID principles
- Clean Architecture
- Feature-first modular structure
- Production-grade state management
- Proper separation of concerns
- Strict typing
- Reusable design systems
- Optimized rendering patterns

---

# Primary Goal

Create a production-grade Flutter app that can scale to millions of users, is maintainable by large teams, optimized for low-end devices, premium, easy to extend, easy to debug, easy to test, and has near-zero technical debt.

---

# Required Architecture

Use Feature-First Clean Architecture.

```txt
lib/
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── services/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   ├── widgets/
│   ├── extensions/
│   ├── animations/
│   ├── performance/
│   └── accessibility/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── farms/
│   ├── ai_reports/
│   ├── maps/
│   ├── crops/
│   ├── weather/
│   ├── alerts/
│   ├── assistant/
│   └── profile/
├── shared/
│   ├── models/
│   ├── widgets/
│   ├── providers/
│   ├── repositories/
│   └── design_system/
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── bootstrap.dart
│   └── dependency_injection.dart
└── main.dart
```

---

# Code Quality Rules

Code must pass `flutter analyze` with zero issues, follow Effective Dart, be strongly typed, avoid duplicate logic, use immutable models, use const constructors, enforce lint rules, have proper error handling, and avoid massive widget files.

Target 250 to 300 lines per file where practical. Split widgets aggressively and extract reusable components.

Avoid god classes, giant screens, business logic inside UI, random utility dumping, tight coupling, deep nesting, and setState-heavy architecture.

---

# State Management

Use Riverpod where possible, or Bloc where architecture benefits.

Include repository pattern, service layer, use cases, state isolation, cached state, and offline synchronization support.

Avoid Provider-only beginner architecture, massive global states, and unstructured state flow.

---

# Performance Engineering

The app must be optimized aggressively:

- Smooth on low-end Android devices
- Stable 60 FPS minimum
- 120 FPS capable on flagship devices
- Low memory usage
- Minimal battery drain

Implement RepaintBoundary, lazy rendering, widget memoization, cached selectors, efficient rebuilds, pagination, isolates where needed, optimized animations, efficient streams, debouncing, smart caching, and adaptive rendering quality.

Avoid unnecessary rebuilds, nested scroll lag, heavy blur everywhere, unoptimized ListViews, re-rendering maps, and large widget trees.

---

# UI Engineering

Create a reusable design system with theme extensions, token-based spacing, responsive layout, adaptive scaling, dark/light architecture, and accessibility support.

Include typography tokens, radius tokens, animation tokens, color tokens, elevation tokens, glassmorphism utilities, and adaptive spacing utilities.

---

# App Performance Utilities

Implement FPS monitoring tools, render performance helpers, adaptive graphics quality manager, device capability detection, performance mode toggles, and memory usage safeguards.

Create automatic low-end optimizations, reduced animation mode, dynamic blur scaling, and battery-aware rendering.

---

# Network Architecture

Implement offline-first networking, retry handling, request cancellation, debouncing, caching, background sync queues, and optimistic updates.

Use Dio client, interceptors, typed API responses, error wrappers, and API abstraction layers.

---

# Database and Storage

Use Supabase, local cache layer, repository abstraction, and typed models.

Implement smart cache invalidation, conflict resolution, background synchronization, and sync queue architecture.

---

# Error Handling

Create a centralized error system with typed exceptions, failure models, user-safe error messages, and crash-safe architecture.

The app must never crash on API failure, freeze on bad network, show ugly red errors, or lose offline data.

---

# Security

Implement secure storage, API key protection, environment configs, token refresh handling, request sanitization, and proper auth flow.

Never hardcode secrets, expose service keys, or store sensitive data insecurely.

---

# Testing Requirements

Include unit tests, widget tests, repository tests, and integration-ready structure.

Architecture must support easy mocking, dependency injection, and automated testing.

---

# Dev Experience

Implement clean logging, environment configs, build flavors, feature flags, debug overlays, and performance debugging tools.

Add README, architecture documentation, folder explanation, and setup instructions.

---

# Animation Engineering

Animations must be GPU optimized, use transforms instead of rebuilds, avoid layout thrashing, and support reduced motion accessibility.

Use Flutter Animate, implicit animations, Rive where needed, and optimized Hero transitions.

---

# Scalability

The architecture should support future additions like push notifications, AI edge inference, real-time collaboration, market pricing, drone integrations, IoT sensors, farm analytics, a web dashboard, and an admin panel without requiring major refactors.

---

# Final Result

The final codebase should feel like a real startup built it, senior engineers maintain it, it could pass enterprise code review, it is App Store and Play Store ready, and it is optimized professionally.

The app must not look or behave like tutorial code, beginner Flutter projects, AI-generated spaghetti code, unnecessary overengineering, or unmaintainable widget trees.

It should feel elegant, fast, modular, clean, premium, robust, and industry standard.
