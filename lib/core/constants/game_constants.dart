abstract final class GameConstants {
  static const int freeGridSize = 3;
  static const int premiumGridSize = 4;
  static const int freePracticeLimit = 5;

  static const int suspiciousDurationMs3x3 = 40 * 60 * 1000;
  static const int suspiciousDurationMs4x4 = 60 * 60 * 1000;
  static const int inactivityThresholdMs = 2 * 60 * 1000;
  static const int maxInactivePeriods = 3;

  static const int minValidAnswersPerCell = 3;
  static const int idealValidAnswersPerCell = 8;

  static const int mistakePenalty = 15;
  static const int hintScorePenalty = 5;

  static const int interstitialEveryNPractice = 3;

  static const int searchDebounceMs = 200;
  static const int searchDefaultLimit = 20;
  static const int maxRecentPicks = 10;
}
