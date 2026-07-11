import '../constants/game_constants.dart';
import 'rarity.dart';

abstract final class ScoringEngine {
  /// Per-cell speed multiplier (scoring v2).
  static double speedBonus(int responseTimeMs) {
    if (responseTimeMs < 30000) return 1.25;
    if (responseTimeMs < 60000) return 1.10;
    if (responseTimeMs < 120000) return 1.0;
    return 0.90;
  }

  /// Hybrid answer quality: obscurity + inverse cell usage (0–100).
  static double answerQuality({
    required double obscurityScore,
    required double usagePercentage,
  }) {
    return RarityCalculator.answerQuality(
      obscurityScore: obscurityScore,
      usagePercentage: usagePercentage,
    );
  }

  static double calculateCellScore({
    required double usagePercentage,
    required int responseTimeMs,
    required int mistakesOnCell,
    double obscurityScore = 50,
  }) {
    final quality = answerQuality(
      obscurityScore: obscurityScore,
      usagePercentage: usagePercentage,
    );
    final qualityFactor = 0.7 + (quality / 100) * 0.8;
    final bonus = speedBonus(responseTimeMs);
    final penalty = mistakesOnCell * GameConstants.mistakePenalty;
    return (GameConstants.baseCellScore * qualityFactor * bonus - penalty).clamp(
      8.0,
      double.infinity,
    );
  }

  /// Weighted hint penalty by reveal depth (matches server hint_penalty_for_type).
  static int hintPenaltyForType(String hintType) {
    return switch (hintType) {
      'nationality' => 4,
      'position' => 6,
      'first_letter' => 9,
      'career_league' => 12,
      'retired_status' => 14,
      'career_club' => 18,
      _ => GameConstants.hintScorePenalty,
    };
  }

  /// Session pace: ideal ~6 minutes for 3×3.
  static double paceMultiplier(int totalDurationMs) {
    final minutes = totalDurationMs / 60000.0;
    return (1.10 - (minutes - 6) * 0.015).clamp(0.75, 1.10);
  }

  static double calculateSessionScore({
    required List<double> cellScores,
    required int hintsUsed,
    int mistakes = 0,
    int completionBonus = 0,
    int hintPenaltySum = 0,
    int totalDurationMs = 0,
  }) {
    final base = cellScores.fold<double>(0, (a, b) => a + b);
    final hintsCost = hintPenaltySum > 0
        ? hintPenaltySum
        : hintsUsed * GameConstants.hintScorePenalty;
    final raw = base +
        completionBonus -
        hintsCost -
        mistakes * GameConstants.mistakePenalty;
    final paced = totalDurationMs > 0 ? raw * paceMultiplier(totalDurationMs) : raw;
    return paced.clamp(0, double.infinity);
  }

  /// Light scoring for Quick Grid — speed + accuracy, no rarity/pace grind.
  static double quickGridCellScore({
    required int remainingSessionMs,
  }) {
    final frac = (remainingSessionMs / (GameConstants.quickGridDurationSec * 1000))
        .clamp(0.0, 1.0);
    return GameConstants.quickGridBaseCellScore +
        GameConstants.quickGridMaxSpeedBonus * frac;
  }

  static double quickGridSessionScore({
    required List<double> cellScores,
    required int mistakes,
  }) {
    final base = cellScores.fold<double>(0, (a, b) => a + b);
    return (base - mistakes * GameConstants.quickGridMistakePenalty)
        .clamp(0, double.infinity);
  }

  static int completionBonusForMode(String mode, {required bool fullGrid}) {
    if (!fullGrid) return 0;
    return switch (mode) {
      'daily' || 'challenge' => GameConstants.dailyCompletionBonus,
      _ => 0,
    };
  }

  static double challengeScore({
    required double finalScore,
    required int mistakes,
    required int hintsUsed,
    required int totalDurationMs,
  }) {
    return finalScore -
        (mistakes * 10) -
        (hintsUsed * 5) -
        (totalDurationMs / 60000 * 0.5);
  }
}
