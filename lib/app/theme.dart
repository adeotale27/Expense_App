import 'package:flutter/material.dart';

class AppColors {
  /// Splitwise-adjacent teal for money/trust, Spendee-like energy on accents.
  static const primary = Color(0xFF0FBE8F);
  static const primaryDeep = Color(0xFF0A8F6C);
  static const mint = Color(0xFF3EE0B0);
  static const coral = Color(0xFFFF6B57);
  static const violet = Color(0xFF6D5EF7);
  static const ink = Color(0xFF0E1A16);
  static const fog = Color(0xFFF3FBF8);
  static const darkCanvas = Color(0xFF07120F);
  static const darkCard = Color(0xFF10241E);
  static const success = Color(0xFF12805C);
  static const warning = Color(0xFFE0A106);
  static const error = Color(0xFFD64545);
}

class AppTheme {
  static const motion = Duration(milliseconds: 220);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD4F8EC),
      onPrimaryContainer: Color(0xFF04382B),
      secondary: AppColors.violet,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8E4FF),
      onSecondaryContainer: Color(0xFF241B63),
      tertiary: AppColors.coral,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.fog,
      onSurface: AppColors.ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFE7F6F0),
      surfaceContainerHighest: Color(0xFFD5EEE5),
      outline: Color(0xFFB7D4C8),
      outlineVariant: Color(0xFFD7EDE4),
    );
    return _base(scheme, dark: false);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF5EE6C3),
      onPrimary: Color(0xFF043226),
      primaryContainer: Color(0xFF0F3D32),
      onPrimaryContainer: Color(0xFFD4F8EC),
      secondary: Color(0xFFB3A8FF),
      onSecondary: Color(0xFF1B1648),
      secondaryContainer: Color(0xFF3D348F),
      onSecondaryContainer: Color(0xFFEDE9FF),
      tertiary: Color(0xFFFF9B80),
      onTertiary: Color(0xFF3A1208),
      error: Color(0xFFFF8A80),
      onError: Color(0xFF3B0A08),
      surface: AppColors.darkCanvas,
      onSurface: Color(0xFFEFFAF5),
      surfaceContainerLowest: AppColors.darkCard,
      surfaceContainerLow: Color(0xFF16352C),
      surfaceContainerHighest: Color(0xFF1D4338),
      outline: Color(0xFF2E5A4C),
      outlineVariant: Color(0xFF1A3A31),
    );
    return _base(scheme, dark: true);
  }

  static ThemeData _base(ColorScheme scheme, {required bool dark}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.28 : 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
