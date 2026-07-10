abstract final class GameConstants {
  static const int gridSize = 3;
  static const int freeGridSize = 3;
  static const int premiumGridSize = 4;
  /// Max practice sessions per calendar day (free users).
  static const int freePracticeDailyLimit = 5;

  /// Max practice sessions per calendar day (premium — ad-free between sessions).
  static const int premiumPracticeDailyLimit = 10;

  static const int suspiciousDurationMs3x3 = 40 * 60 * 1000;
  static const int suspiciousDurationMs4x4 = 60 * 60 * 1000;
  static const int inactivityThresholdMs = 2 * 60 * 1000;
  static const int maxInactivePeriods = 3;

  static const int minValidAnswersPerCell = 3;
  static const int idealValidAnswersPerCell = 8;

  static const int mistakePenalty = 15;
  /// Fallback flat hint penalty when hint types are unknown.
  static const int hintScorePenalty = 5;

  /// Base points per correct cell before quality/speed (scoring v2).
  static const int baseCellScore = 10;

  /// Extra points from rarity: (100 - usage%) * multiplier (legacy preview).
  static const double rarityScoreMultiplier = 0.45;

  /// Bonus for completing the full daily/challenge grid (scoring v2).
  static const int dailyCompletionBonus = 25;

  static const int interstitialEveryNPractice = 3;

  static const int searchDebounceMs = 200;
  static const int searchDefaultLimit = 20;
  static const int maxRecentPicks = 10;
}
