import 'package:flutter/material.dart';

class DesignTokens {
  // Colors
  static const Color primaryDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color accentColor = Color(0xFF34C759); // Apple-like green
  static const Color glassmorphismColorDark = Color(0x33FFFFFF);
  static const Color glassmorphismBorderDark = Color(0x4DFFFFFF);

  // Spacing (Adaptive scale base)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;

  // Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  // Typography Tokens
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  // Animations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 600);
  
  static const Curve defaultCurve = Curves.easeInOutQuart;
}
