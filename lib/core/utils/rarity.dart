import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum RarityTier {
  common,
  rare,
  epic,
  legendary,
  mythic;

  /// Legacy cell-usage tiers (kept for older payloads).
  static RarityTier fromUsagePercentage(double usage) {
    if (usage > 50) return RarityTier.common;
    if (usage > 25) return RarityTier.rare;
    if (usage > 10) return RarityTier.epic;
    if (usage > 3) return RarityTier.legendary;
    return RarityTier.mythic;
  }

  /// Scoring v2: hybrid answer quality (0–100).
  static RarityTier fromAnswerQuality(double quality) {
    if (quality >= 80) return RarityTier.mythic;
    if (quality >= 65) return RarityTier.legendary;
    if (quality >= 50) return RarityTier.epic;
    if (quality >= 35) return RarityTier.rare;
    return RarityTier.common;
  }

  Color get color => switch (this) {
        RarityTier.common => AppColors.rarityCommon,
        RarityTier.rare => AppColors.rarityRare,
        RarityTier.epic => AppColors.rarityEpic,
        RarityTier.legendary => AppColors.rarityLegendary,
        RarityTier.mythic => AppColors.rarityMythic,
      };

  String get label => name[0].toUpperCase() + name.substring(1);
}

abstract final class RarityCalculator {
  static double rarityScore(double usagePercentage) =>
      (100 - usagePercentage).clamp(0, 100);

  /// 55% obscurity + 45% inverse cell usage.
  static double answerQuality({
    required double obscurityScore,
    required double usagePercentage,
  }) {
    final obscurity = obscurityScore.clamp(0, 100);
    final inverseUsage = rarityScore(usagePercentage);
    return (obscurity * 0.55 + inverseUsage * 0.45).clamp(0, 100);
  }
}
