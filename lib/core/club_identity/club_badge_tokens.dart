import 'package:flutter/material.dart';

/// CrossBall Original Club Identity — unified design tokens.
/// Every club badge shares identical proportions, stroke, shadow and motion rules.
abstract final class ClubBadgeTokens {
  /// Primary shape: soft rounded shield (consistent across all clubs).
  static const shapeAspectRatio = 1.18;

  static const cornerSoftness = 0.14;
  static const borderThicknessRatio = 0.045;
  static const innerBorderRatio = 0.018;
  static const glassHighlightRatio = 0.45;

  static const glowBlurMax = 8.0;
  static const glowAlphaMax = 0.35;
  static const selectedGlowBoost = 0.55;
  static const solvedGlowBoost = 0.4;

  static const labelMinFontSize = 11.0;
  static const labelMaxFontSize = 13.0;
  static const labelLetterSpacing = 0.25;
  static const labelMaxWidthFactor = 1.55;

  static const chipPaddingH = 10.0;
  static const chipPaddingV = 6.0;
  static const chipGap = 8.0;
  static const tilePadding = 8.0;

  static const appearDuration = Duration(milliseconds: 280);
  static const stateDuration = Duration(milliseconds: 220);
  static const scaleSelected = 1.06;
  static const scaleSolved = 1.02;

  static BorderRadius chipRadius = BorderRadius.circular(999);
  static BorderRadius tileRadius = BorderRadius.circular(14);

  /// High-contrast mode: stronger borders, no subtle glass fade.
  static double borderMultiplier(BuildContext context) {
    return MediaQuery.highContrastOf(context) ? 1.35 : 1.0;
  }

  static double glowMultiplier(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return 0;
    return MediaQuery.highContrastOf(context) ? 0.6 : 1.0;
  }

  static Color rimColor(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (MediaQuery.highContrastOf(context)) {
      return isDark ? Colors.white : Colors.black87;
    }
    return accent;
  }
}

enum ClubBadgeVisualState {
  normal,
  selected,
  solved,
  highlighted,
}

enum ClubBadgeShape {
  roundedShield,
}
