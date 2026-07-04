import 'package:flutter/material.dart';

/// CrossBall premium football palette — synced with `design/stitch/DESIGN.md`.
abstract final class AppColors {
  // Brand — football green + electric lime
  static const footballGreen = Color(0xFFA1D494);
  static const footballGreenDark = Color(0xFF3B6934);
  static const footballGreenDeep = Color(0xFF2D5A27);
  static const electricLime = Color(0xFFC3F400);
  static const electricLimeDim = Color(0xFFABD600);
  static const gold = Color(0xFFE9C349);
  static const goldLight = Color(0xFFFFE088);

  // Semantic
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFFFB4AB);
  static const errorStrong = Color(0xFFE53935);
  static const legendary = Color(0xFFAB47BC);

  // Dark Stadium — pitch graphite (default premium)
  static const darkBackground = Color(0xFF121416);
  static const darkSurface = Color(0xFF1E2022);
  static const darkSurfaceHigh = Color(0xFF282A2C);
  static const darkSurfaceHighest = Color(0xFF333537);
  static const darkTextPrimary = Color(0xFFE2E2E5);
  static const darkTextSecondary = Color(0xFFC2C9BB);
  static const darkOutline = Color(0xFF42493E);

  static const onLime = Color(0xFF161E00);

  // Light Pitch — Soft Mint (#F0F7F0) per Stitch design system
  static const lightBackground = Color(0xFFF0F7F0);
  static const lightBackgroundAlt = Color(0xFFF7FBF7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF7FBF8);
  static const lightPrimary = Color(0xFF2E7D32);
  static const lightAccent = Color(0xFF7CB342);
  static const lightLime = Color(0xFF9CCC65);
  static const lightTextPrimary = Color(0xFF1A2E1F);
  static const lightTextSecondary = Color(0xFF5A6B5E);
  static const lightOutline = Color(0xFFD8E8DA);

  // Legacy aliases
  static const pitchDeep = Color(0xFF051F14);
  static const pitchForest = Color(0xFF0A2A1B);
  static const pitchGreen = footballGreenDeep;
  static const pitchGreenLight = footballGreen;
  static const copper = gold;
  static const copperDark = Color(0xFFCCA730);
  static const silver = darkTextSecondary;
  static const silverLight = darkTextPrimary;
  static const background = darkBackground;
  static const surface = darkSurface;
  static const surfaceElevated = darkSurfaceHigh;
  static const accentGold = gold;
  static const accentWhite = darkTextPrimary;
  static const textPrimary = darkTextPrimary;
  static const textSecondary = darkTextSecondary;
  static const lightPitchBackground = lightBackground;
  static const lightPitchSurface = lightSurface;
  static const lightPitchSurfaceElevated = lightSurfaceElevated;
  static const lightPitchPrimary = lightPrimary;
  static const lightPitchSecondary = lightAccent;
  static const lightPitchGold = gold;
  static const lightPitchTextPrimary = lightTextPrimary;
  static const lightPitchTextSecondary = lightTextSecondary;
  static const lightPitchStripe = lightBackgroundAlt;

  // Rarity tiers
  static const rarityCommon = Color(0xFF9E9E9E);
  static const rarityRare = Color(0xFF42A5F5);
  static const rarityEpic = Color(0xFFAB47BC);
  static const rarityLegendary = gold;
  static const rarityMythic = Color(0xFFFF6B35);
}

/// Theme-aware semantic colors via [ThemeExtension].
class CrossBallColors extends ThemeExtension<CrossBallColors> {
  const CrossBallColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.accent,
    required this.lime,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
    required this.iconTint,
    required this.success,
    required this.error,
    required this.glassBorder,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color accent;
  final Color lime;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;
  final Color iconTint;
  final Color success;
  final Color error;
  final Color glassBorder;

  /// Dark Stadium — default premium night pitch experience.
  static const darkStadium = CrossBallColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceHigh,
    primary: AppColors.footballGreen,
    accent: AppColors.gold,
    lime: AppColors.electricLime,
    secondaryAccent: AppColors.darkTextSecondary,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    cardBorder: Color(0x14FFFFFF),
    iconTint: AppColors.footballGreen,
    success: AppColors.success,
    error: AppColors.errorStrong,
    glassBorder: Color(0x14FFFFFF),
  );

  /// Light Pitch — soft mint, white cards, fresh football green.
  static const lightPitch = CrossBallColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    primary: AppColors.lightPrimary,
    accent: AppColors.gold,
    lime: AppColors.lightLime,
    secondaryAccent: AppColors.lightAccent,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    cardBorder: Color(0x1A2E7D32),
    iconTint: AppColors.lightPrimary,
    success: Color(0xFF2E7D32),
    error: AppColors.errorStrong,
    glassBorder: Color(0x1A000000),
  );

  static const darkGoldStadium = CrossBallColors(
    background: Color(0xFF0F0E0A),
    surface: Color(0xFF1A1810),
    surfaceElevated: Color(0xFF252117),
    primary: AppColors.gold,
    accent: AppColors.goldLight,
    lime: AppColors.electricLime,
    secondaryAccent: AppColors.gold,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    cardBorder: Color(0x33E9C349),
    iconTint: AppColors.gold,
    success: AppColors.success,
    error: AppColors.errorStrong,
    glassBorder: Color(0x33E9C349),
  );

  /// Premium light — classic white pitch with gold accents.
  static const lightClassic = CrossBallColors(
    background: Color(0xFFFAFAF5),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF5F0E6),
    primary: AppColors.gold,
    accent: AppColors.copperDark,
    lime: AppColors.lightPrimary,
    secondaryAccent: AppColors.gold,
    textPrimary: Color(0xFF1A1A14),
    textSecondary: Color(0xFF5C5A52),
    cardBorder: Color(0x33E9C349),
    iconTint: AppColors.gold,
    success: Color(0xFF2E7D32),
    error: AppColors.errorStrong,
    glassBorder: Color(0x1A000000),
  );

  static const dark = darkStadium;
  static const light = lightPitch;

  @override
  CrossBallColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? accent,
    Color? lime,
    Color? secondaryAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBorder,
    Color? iconTint,
    Color? success,
    Color? error,
    Color? glassBorder,
  }) =>
      CrossBallColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        primary: primary ?? this.primary,
        accent: accent ?? this.accent,
        lime: lime ?? this.lime,
        secondaryAccent: secondaryAccent ?? this.secondaryAccent,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        cardBorder: cardBorder ?? this.cardBorder,
        iconTint: iconTint ?? this.iconTint,
        success: success ?? this.success,
        error: error ?? this.error,
        glassBorder: glassBorder ?? this.glassBorder,
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
      lime: Color.lerp(lime, other.lime, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      iconTint: Color.lerp(iconTint, other.iconTint, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

extension CrossBallColorsContext on BuildContext {
  CrossBallColors get cb => Theme.of(this).extension<CrossBallColors>()!;
}
