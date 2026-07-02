import 'package:flutter/material.dart';

/// CrossBall design tokens — premium pitch green + copper/silver (matches app icon).
abstract final class AppColors {
  // Brand (shared)
  static const pitchDeep = Color(0xFF051F14);
  static const pitchForest = Color(0xFF0A2A1B);
  static const pitchGreen = Color(0xFF124A32);
  static const pitchGreenLight = Color(0xFF1F6B47);
  static const copper = Color(0xFFC5A391);
  static const copperDark = Color(0xFFA67B6B);
  static const silver = Color(0xFFA8A9AD);
  static const silverLight = Color(0xFFD1D2D6);
  static const error = Color(0xFFE53935);

  // Dark mode surfaces
  static const darkBackground = Color(0xFF051F14);
  static const darkSurface = Color(0xFF0A2A1B);
  static const darkSurfaceElevated = Color(0xFF124A32);
  static const darkTextPrimary = Color(0xFFF5F5F5);
  static const darkTextSecondary = Color(0xFFB0C4BC);

  // Light mode surfaces
  static const lightBackground = Color(0xFFF4F7F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFE8F0EC);
  static const lightTextPrimary = Color(0xFF051F14);
  static const lightTextSecondary = Color(0xFF4A6358);

  // Legacy aliases (dark defaults for gradual migration)
  static const background = darkBackground;
  static const surface = darkSurface;
  static const surfaceElevated = darkSurfaceElevated;
  static const accentGold = copper;
  static const accentWhite = darkTextPrimary;
  static const textPrimary = darkTextPrimary;
  static const textSecondary = darkTextSecondary;

  // Rarity tiers
  static const rarityCommon = Color(0xFF9E9E9E);
  static const rarityRare = Color(0xFF42A5F5);
  static const rarityEpic = Color(0xFFAB47BC);
  static const rarityLegendary = Color(0xFFC5A391);
  static const rarityMythic = Color(0xFFFF6B35);
}

/// Theme-aware color accessor via [ThemeExtension].
class CrossBallColors extends ThemeExtension<CrossBallColors> {
  const CrossBallColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.accent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
    required this.iconTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color accent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;
  final Color iconTint;

  static const dark = CrossBallColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    primary: AppColors.pitchGreenLight,
    accent: AppColors.copper,
    secondaryAccent: AppColors.silver,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    cardBorder: Color(0x33C5A391),
    iconTint: AppColors.copper,
  );

  static const light = CrossBallColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    primary: AppColors.pitchForest,
    accent: AppColors.copperDark,
    secondaryAccent: AppColors.silver,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    cardBorder: Color(0x33A67B6B),
    iconTint: AppColors.pitchForest,
  );

  @override
  CrossBallColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? accent,
    Color? secondaryAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBorder,
    Color? iconTint,
  }) =>
      CrossBallColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        primary: primary ?? this.primary,
        accent: accent ?? this.accent,
        secondaryAccent: secondaryAccent ?? this.secondaryAccent,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        cardBorder: cardBorder ?? this.cardBorder,
        iconTint: iconTint ?? this.iconTint,
      );

  @override
  CrossBallColors lerp(ThemeExtension<CrossBallColors>? other, double t) {
    if (other is! CrossBallColors) return this;
    return CrossBallColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      iconTint: Color.lerp(iconTint, other.iconTint, t)!,
    );
  }
}

extension CrossBallColorsContext on BuildContext {
  CrossBallColors get cb => Theme.of(this).extension<CrossBallColors>()!;
}
