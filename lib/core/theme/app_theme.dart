import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(CrossBallColors.dark, Brightness.dark);

  static ThemeData light() => _build(CrossBallColors.light, Brightness.light);

  static ThemeData _build(CrossBallColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.textPrimary,
      secondary: colors.accent,
      onSecondary: isDark ? AppColors.pitchDeep : Colors.white,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: scheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceElevated,
        elevation: isDark ? 4 : 1,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.cardBorder),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: isDark ? AppColors.pitchDeep : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: colors.textSecondary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.accent),
      iconTheme: IconThemeData(color: colors.iconTint),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textSecondary),
        bodySmall: TextStyle(color: colors.textSecondary, fontSize: 12),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
