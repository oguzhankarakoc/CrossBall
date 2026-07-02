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
    final rarity = RarityCalculator.rarityScore(usagePercentage);
    final bonus = speedBonus(responseTimeMs);
    final penalty = mistakesOnCell * GameConstants.mistakePenalty;
    return (rarity * bonus - penalty).clamp(0, double.infinity);
  }

  static double calculateSessionScore({
    required List<double> cellScores,
    required int hintsUsed,
  }) {
    final base = cellScores.fold<double>(0, (a, b) => a + b);
    return (base - hintsUsed * GameConstants.hintScorePenalty)
        .clamp(0, double.infinity);
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
