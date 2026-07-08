import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/constants/game_constants.dart';
import 'package:crossball/core/utils/rarity.dart';
import 'package:crossball/core/utils/scoring.dart';

void main() {
  group('RarityCalculator', () {
    test('rarity score decreases with usage', () {
      expect(RarityCalculator.rarityScore(67), closeTo(33, 0.01));
      expect(RarityCalculator.rarityScore(4), closeTo(96, 0.01));
    });

    test('rarity score clamps at 0', () {
      expect(RarityCalculator.rarityScore(150), 0);
    });
  });

  group('RarityTier', () {
    test('tier boundaries', () {
      expect(RarityTier.fromUsagePercentage(67), RarityTier.common);
      expect(RarityTier.fromUsagePercentage(35), RarityTier.rare);
      expect(RarityTier.fromUsagePercentage(15), RarityTier.epic);
      expect(RarityTier.fromUsagePercentage(5), RarityTier.legendary);
      expect(RarityTier.fromUsagePercentage(1), RarityTier.mythic);
    });
  });

  group('ScoringEngine', () {
    test('speed bonus tiers', () {
      expect(ScoringEngine.speedBonus(20000), 1.3);
      expect(ScoringEngine.speedBonus(45000), 1.15);
      expect(ScoringEngine.speedBonus(90000), 1.0);
      expect(ScoringEngine.speedBonus(150000), 0.85);
    });

    test('cell score includes base points for common picks', () {
      final score = ScoringEngine.calculateCellScore(
        usagePercentage: 100,
        responseTimeMs: 60000,
        mistakesOnCell: 0,
      );
      expect(score, closeTo(GameConstants.baseCellScore.toDouble(), 0.01));
    });

    test('cell score with rarity and speed', () {
      final score = ScoringEngine.calculateCellScore(
        usagePercentage: 4,
        responseTimeMs: 25000,
        mistakesOnCell: 0,
      );
      expect(
        score,
        closeTo((GameConstants.baseCellScore + 96 * GameConstants.rarityScoreMultiplier) * 1.3, 0.01),
      );
    });

    test('mistake penalty applied', () {
      final score = ScoringEngine.calculateCellScore(
        usagePercentage: 50,
        responseTimeMs: 60000,
        mistakesOnCell: 2,
      );
      final core = GameConstants.baseCellScore + 50 * GameConstants.rarityScoreMultiplier;
      expect(score, closeTo((core * 1.0 - 30).clamp(GameConstants.baseCellScore * 0.5, double.infinity), 0.01));
    });

    test('mistakes reduce session score', () {
      final score = ScoringEngine.calculateSessionScore(
        cellScores: [12, 12, 12],
        hintsUsed: 0,
        mistakes: 2,
        completionBonus: GameConstants.dailyCompletionBonus,
      );
      expect(
        score,
        36 + GameConstants.dailyCompletionBonus - 2 * GameConstants.mistakePenalty,
      );
    });

    test('session score aggregates cells, completion bonus, minus hints', () {
      final score = ScoringEngine.calculateSessionScore(
        cellScores: [12, 12, 12],
        hintsUsed: 1,
        completionBonus: GameConstants.dailyCompletionBonus,
      );
      expect(
        score,
        36 + GameConstants.dailyCompletionBonus - GameConstants.hintScorePenalty,
      );
    });

    test('full common daily grid still earns meaningful points', () {
      final cellScores = List<double>.filled(9, GameConstants.baseCellScore.toDouble());
      final score = ScoringEngine.calculateSessionScore(
        cellScores: cellScores,
        hintsUsed: 1,
        completionBonus: GameConstants.dailyCompletionBonus,
      );
      expect(score, greaterThan(100));
    });
  });
}
