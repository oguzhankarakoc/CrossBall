import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData darkStadium() => _build(CrossBallColors.darkStadium, Brightness.dark);

  static ThemeData darkGold() => _build(CrossBallColors.darkGoldStadium, Brightness.dark);

  static ThemeData lightPitch() => _build(CrossBallColors.lightPitch, Brightness.light);

  static ThemeData lightClassic() => _build(CrossBallColors.lightClassic, Brightness.light);

  static ThemeData dark() => darkStadium();

  static ThemeData light() => lightPitch();

  static ThemeData _build(CrossBallColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: isDark ? AppColors.pitchDeep : Colors.white,
      secondary: colors.lime,
      onSecondary: AppColors.onLime,
      tertiary: colors.accent,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: colors.error,
      onError: Colors.white,
    );

    // Base on brightness-aware Material text theme so headline*/display* inherit
    // correct contrast in both light and dark modes.
    final baseInter = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness, colorScheme: scheme).textTheme,
    );

    final textTheme = baseInter.apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    ).copyWith(
      displayLarge: baseInter.displayLarge?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.96,
        height: 56 / 48,
        color: colors.textPrimary,
      ),
      displaySmall: baseInter.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
      ),
      headlineMedium: baseInter.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.28,
        height: 36 / 28,
        color: colors.textPrimary,
      ),
      headlineSmall: baseInter.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 32 / 24,
        color: colors.textPrimary,
      ),
      titleLarge: baseInter.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 28 / 20,
        color: colors.textPrimary,
      ),
      titleMedium: baseInter.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: colors.textPrimary,
      ),
      titleSmall: baseInter.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: colors.textPrimary,
      ),
      bodyLarge: baseInter.bodyLarge?.copyWith(color: colors.textPrimary, height: 1.45),
      bodyMedium: baseInter.bodyMedium?.copyWith(color: colors.textSecondary, height: 1.4),
      bodySmall: baseInter.bodySmall?.copyWith(
        color: colors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseInter.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        height: 16 / 12,
        color: colors.textSecondary,
      ),
      // Surface labels — never onLime (that belongs only on filled lime CTAs).
      labelLarge: baseInter.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: colors.textPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: scheme,
      extensions: [colors],
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface.withValues(alpha: isDark ? 0.85 : 0.92),
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceElevated,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlBorder,
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.cardBorder),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.lime,
          foregroundColor: AppColors.onLime,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
          elevation: 0,
          shadowColor: colors.lime.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 14,
            letterSpacing: 0.8,
            color: AppColors.onLime,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.primary.withValues(alpha: 0.65)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceHighest.withValues(alpha: 0.35) : colors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: AppRadius.lgBorder,
          borderSide: BorderSide(color: colors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorder,
          borderSide: BorderSide(color: colors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorder,
          borderSide: BorderSide(color: colors.lime.withValues(alpha: 0.85), width: 2),
        ),
        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.75)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceElevated,
        side: BorderSide(color: colors.glassBorder),
        labelStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.lime),
      iconTheme: IconThemeData(color: colors.iconTint),
      textTheme: textTheme,
    );
  }
}
