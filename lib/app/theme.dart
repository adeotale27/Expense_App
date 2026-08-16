import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6D5EF7);
  static const mint = Color(0xFF1ED6A5);
  static const coral = Color(0xFFFF7A59);
  static const ink = Color(0xFF10121A);
  static const fog = Color(0xFFF4F5FA);
  static const darkCanvas = Color(0xFF0B0D14);
  static const darkCard = Color(0xFF151823);
  static const success = Color(0xFF1B7F4E);
  static const warning = Color(0xFFC27803);
  static const error = Color(0xFFB42318);
}

class AppTheme {
  static const motion = Duration(milliseconds: 220);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8E4FF),
      onPrimaryContainer: Color(0xFF241B63),
      secondary: AppColors.mint,
      onSecondary: Color(0xFF06281F),
      secondaryContainer: Color(0xFFD4F8EC),
      onSecondaryContainer: Color(0xFF053226),
      tertiary: AppColors.coral,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.fog,
      onSurface: AppColors.ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFEBEDF5),
      surfaceContainerHighest: Color(0xFFE2E5F0),
      outline: Color(0xFFC5CAD8),
      outlineVariant: Color(0xFFDDE1EC),
    );
    return _base(scheme, dark: false);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFB3A8FF),
      onPrimary: Color(0xFF1B1648),
      primaryContainer: Color(0xFF3D348F),
      onPrimaryContainer: Color(0xFFEDE9FF),
      secondary: Color(0xFF5EE6C3),
      onSecondary: Color(0xFF06281F),
      secondaryContainer: Color(0xFF0F3D32),
      onSecondaryContainer: Color(0xFFD4F8EC),
      tertiary: Color(0xFFFF9B80),
      onTertiary: Color(0xFF3A1208),
      error: Color(0xFFFF8A80),
      onError: Color(0xFF3B0A08),
      surface: AppColors.darkCanvas,
      onSurface: Color(0xFFF2F4FA),
      surfaceContainerLowest: AppColors.darkCard,
      surfaceContainerLow: Color(0xFF1B1F2C),
      surfaceContainerHighest: Color(0xFF262B3A),
      outline: Color(0xFF3C4254),
      outlineVariant: Color(0xFF2A3040),
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
          letterSpacing: -0.4,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.28 : 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
