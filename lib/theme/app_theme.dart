import 'package:flutter/material.dart';

class AppTheme {
  // ── Apple-inspired refined palette ──────────────────────────────────────
  // Deep teal-green that feels premium, not generic "farm green".
  static const primaryTeal = Color(0xFF2F7D4F);
  static const mintAccent = Color(0xFF7ECFA2);
  // Muted indigo-blue for secondary surfaces and accents.
  static const skyBlueAccent = Color(0xFF4C8FB5);
  // Warm amber for alerts and highlights.
  static const warmAmber = Color(0xFFD99A3D);
  // Coral for error / urgent states.
  static const coralRed = Color(0xFFD95C52);
  static const soilBrown = Color(0xFF765B3D);

  static const seed = primaryTeal;

  // ── Light Theme ────────────────────────────────────────────────────────
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryTeal,
      secondary: skyBlueAccent,
      tertiary: warmAmber,
      error: coralRed,
      surface: const Color(0xFFF5F8F1),
      surfaceContainer: const Color(0xFFFFFFFF),
      surfaceContainerHigh: const Color(0xFFEAF2E7),
      surfaceContainerHighest: const Color(0xFFDDE9D8),
      onSurface: const Color(0xFF18231C),
      onSurfaceVariant: const Color(0xFF607066),
      primaryContainer: const Color(0xFFDDEDD6),
      secondaryContainer: const Color(0xFFD9ECF5),
      tertiaryContainer: const Color(0xFFFFE5B8),
      outline: const Color(0xFFB8C7BC),
      outlineVariant: const Color(0xFFD5E0D8),
    );
    return _base(scheme);
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFA6D9AE),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFA6D9AE),
      secondary: const Color(0xFF91BED6),
      tertiary: const Color(0xFFE5B464),
      error: const Color(0xFFFF8A80),
      surface: const Color(0xFF101813),
      surfaceContainer: const Color(0xFF17221B),
      surfaceContainerHigh: const Color(0xFF1F2C23),
      surfaceContainerHighest: const Color(0xFF2B3A30),
      onSurface: const Color(0xFFF3F5EE),
      onSurfaceVariant: const Color(0xFFB7C3BA),
      primaryContainer: const Color(0xFF244733),
      secondaryContainer: const Color(0xFF233D4B),
      tertiaryContainer: const Color(0xFF4B3921),
      outline: const Color(0xFF3F5145),
      outlineVariant: const Color(0xFF26352B),
    );
    return _base(scheme);
  }

  // ── Shared base configuration ──────────────────────────────────────────
  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: scheme.surface,
      textTheme: (isDark
              ? Typography.material2021().white
              : Typography.material2021().black)
          .apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
        backgroundColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? scheme.surfaceContainer : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainer : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // Expose the old name for backwards compat with existing screen references.
  static const deepEmerald = primaryTeal;
  static const softGreenGlow = mintAccent;
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassBackground — premium frosted ambient gradient behind every screen.
// ─────────────────────────────────────────────────────────────────────────────

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [
                    Color(0xFF101813),
                    Color(0xFF142018),
                    Color(0xFF18251D),
                  ]
                : const [
                    Color(0xFFF5F8F1),
                    Color(0xFFEFF7F9),
                    Color(0xFFFFF7E8),
                  ],
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard — refined frosted-glass card used across the entire app.
// ─────────────────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final performance = UiPerformance.of(context);
    final radius = BorderRadius.circular(8);
    final decorated = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: dark
            ? colors.surfaceContainer.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: radius,
        border: Border.all(
          color: dark ? colors.outlineVariant : colors.outlineVariant,
        ),
        boxShadow: [
          if (performance.enableSoftShadows)
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.22 : 0.07),
              blurRadius: performance.shadowBlur + 2,
              offset: Offset(0, performance.shadowYOffset + 2),
            ),
          if (performance.highEnd && !dark)
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.05),
              blurRadius: 18,
              spreadRadius: -10,
            ),
        ],
      ),
      child: child,
    );

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: decorated,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KrishiLogo
// ─────────────────────────────────────────────────────────────────────────────

class KrishiLogo extends StatelessWidget {
  const KrishiLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.secondaryContainer,
          ],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Icon(
        Icons.agriculture_rounded,
        color: colors.primary,
        size: size * 0.6,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UiPerformance — adaptive quality engine for smooth 60fps on low-end devices.
// ─────────────────────────────────────────────────────────────────────────────

enum UiQuality { low, balanced, high }

class UiPerformance {
  const UiPerformance._(this.quality, this.disableAnimations);

  final UiQuality quality;
  final bool disableAnimations;

  static UiPerformance of(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return const UiPerformance._(UiQuality.balanced, false);

    final shortestSide = media.size.shortestSide;
    final narrowLowEndHint = shortestSide <= 360 || media.devicePixelRatio <= 2;
    final conserveMotion =
        media.disableAnimations || media.accessibleNavigation;
    final quality = conserveMotion || narrowLowEndHint
        ? UiQuality.low
        : shortestSide >= 430 && media.devicePixelRatio >= 2.6
            ? UiQuality.high
            : UiQuality.balanced;

    return UiPerformance._(quality, conserveMotion);
  }

  bool get lowEnd => quality == UiQuality.low;
  bool get highEnd => quality == UiQuality.high;
  bool get enableBlur => !lowEnd;
  bool get enableSoftShadows => !lowEnd;
  bool get enableSkeletonAnimation => !disableAnimations && !lowEnd;

  double get blurSigma => switch (quality) {
        UiQuality.low => 0,
        UiQuality.balanced => 8,
        UiQuality.high => 12,
      };

  double get shadowBlur => switch (quality) {
        UiQuality.low => 0,
        UiQuality.balanced => 10,
        UiQuality.high => 16,
      };

  double get shadowYOffset => switch (quality) {
        UiQuality.low => 0,
        UiQuality.balanced => 4,
        UiQuality.high => 8,
      };

  double get animationScale => disableAnimations
      ? 0
      : switch (quality) {
          UiQuality.low => 0.55,
          UiQuality.balanced => 0.78,
          UiQuality.high => 1,
        };

  double glassOpacity(bool dark) => switch (quality) {
        UiQuality.low => dark ? 0.94 : 0.86,
        UiQuality.balanced => dark ? 0.90 : 0.78,
        UiQuality.high => dark ? 0.86 : 0.72,
      };
}
