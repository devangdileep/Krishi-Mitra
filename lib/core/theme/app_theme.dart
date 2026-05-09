import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: DesignTokens.accentColor,
      scaffoldBackgroundColor: DesignTokens.primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.accentColor,
        surface: DesignTokens.surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        titleTextStyle: DesignTokens.heading2,
      ),
      textTheme: const TextTheme(
        displayLarge: DesignTokens.heading1,
        displayMedium: DesignTokens.heading2,
        bodyLarge: DesignTokens.body,
        bodySmall: DesignTokens.caption,
      ),
      useMaterial3: true,
    );
  }
}
