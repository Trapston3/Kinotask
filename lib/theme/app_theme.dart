import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color accentBlue = Color(0xFF007AFF);
  static const Color pitchBlack = Color(0xFF000000);
  static const Color crispWhite = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF4F5F7);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkOutline = Color(0xFF1F1F1F);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentBlue,
      brightness: Brightness.light,
    ).copyWith(
      primary: accentBlue,
      secondary: accentBlue,
      surface: crispWhite,
      onSurface: const Color(0xFF111111),
      outline: const Color(0xFFE4E7EC),
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: crispWhite,
      cardColor: lightSurface,
      dividerColor: const Color(0xFFE9EDF3),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accentBlue,
      secondary: accentBlue,
      surface: pitchBlack,
      onSurface: const Color(0xFFF5F7FA),
      outline: darkOutline,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pitchBlack,
      cardColor: darkSurface,
      dividerColor: darkOutline,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color dividerColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      dividerColor: dividerColor,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.35),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        elevation: 0,
        height: 88,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: accentBlue.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? accentBlue : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? accentBlue : colorScheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
