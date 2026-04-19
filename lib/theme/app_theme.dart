import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Stitch Design Tokens ─────────────────────────────────────────
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color pitchBlack = Color(0xFF000000);
  static const Color islandSurface = Color(0xFF1C1C1E);
  static const Color islandBorder = Color(0xFF2C2C2E);
  static const Color subtleGrey = Color(0xFF8E8E93);
  static const Color destructiveRed = Color(0xFFFF453A);
  static const Color deepWorkOrange = Color(0xFFFF3B30);

  /// Returns the accent color based on whether the Pomodoro timer is active.
  static Color accentForFocusState(bool isTimerActive) =>
      isTimerActive ? deepWorkOrange : accentBlue;

  static const double islandRadius = 32.0;

  // ── Dark Theme (AMOLED-only) ─────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accentBlue,
      secondary: accentBlue,
      surface: pitchBlack,
      onSurface: const Color(0xFFF5F7FA),
      outline: islandBorder,
      onSurfaceVariant: subtleGrey,
      error: destructiveRed,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    final textTheme = baseTextTheme.apply(
      bodyColor: const Color(0xFFF5F7FA),
      displayColor: const Color(0xFFF5F7FA),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pitchBlack,
      dividerColor: islandBorder,
      cardColor: islandSurface,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          fontSize: 34,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.35),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: islandSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(islandRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pitchBlack,
        foregroundColor: const Color(0xFFF5F7FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: const Color(0xFFF5F7FA),
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: islandSurface,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? accentBlue : subtleGrey,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? accentBlue : subtleGrey,
            fontSize: 11,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: islandSurface,
        selectedColor: accentBlue.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: islandBorder),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? accentBlue
              : subtleGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? accentBlue.withValues(alpha: 0.3)
              : islandBorder;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: islandSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: islandBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: islandBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: subtleGrey),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: subtleGrey.withValues(alpha: 0.6),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: islandSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        dragHandleColor: subtleGrey,
      ),
    );
  }

  // Light theme aliases to dark (AMOLED-only app).
  static ThemeData get lightTheme => darkTheme;
}
