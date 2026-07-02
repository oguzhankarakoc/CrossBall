import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum RarityTier {
  common,
  rare,
  epic,
  legendary,
  mythic;

  static RarityTier fromUsagePercentage(double usage) {
    if (usage > 50) return RarityTier.common;
    if (usage > 25) return RarityTier.rare;
    if (usage > 10) return RarityTier.epic;
    if (usage > 3) return RarityTier.legendary;
    return RarityTier.mythic;
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
}
