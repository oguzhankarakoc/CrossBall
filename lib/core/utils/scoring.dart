import '../constants/game_constants.dart';
import 'rarity.dart';

abstract final class ScoringEngine {
  static double speedBonus(int responseTimeMs) {
    if (responseTimeMs < 30000) return 1.3;
    if (responseTimeMs < 60000) return 1.15;
    if (responseTimeMs < 120000) return 1.0;
    return 0.85;
  }

  static double calculateCellScore({
    required double usagePercentage,
    required int responseTimeMs,
    required int mistakesOnCell,
  }) {
    final rarityComponent =
        RarityCalculator.rarityScore(usagePercentage) * GameConstants.rarityScoreMultiplier;
    final core = GameConstants.baseCellScore + rarityComponent;
    final bonus = speedBonus(responseTimeMs);
    final penalty = mistakesOnCell * GameConstants.mistakePenalty;
    return (core * bonus - penalty).clamp(
      GameConstants.baseCellScore * 0.5,
      double.infinity,
    );
  }

  static double calculateSessionScore({
    required List<double> cellScores,
    required int hintsUsed,
    int mistakes = 0,
    int completionBonus = 0,
  }) {
    final base = cellScores.fold<double>(0, (a, b) => a + b);
    return (base +
            completionBonus -
            hintsUsed * GameConstants.hintScorePenalty -
            mistakes * GameConstants.mistakePenalty)
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
