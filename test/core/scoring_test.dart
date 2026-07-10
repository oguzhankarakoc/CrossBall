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

    test('hybrid answer quality blends obscurity and usage', () {
      final quality = RarityCalculator.answerQuality(
        obscurityScore: 80,
        usagePercentage: 20,
      );
      // 0.55*80 + 0.45*80 = 80
      expect(quality, closeTo(80, 0.01));
    });

    test('superstar cold-start stays common-ish', () {
      final quality = RarityCalculator.answerQuality(
        obscurityScore: 10,
        usagePercentage: 90,
      );
      expect(quality, lessThan(35));
      expect(RarityTier.fromAnswerQuality(quality), RarityTier.common);
    });
  });

  group('RarityTier', () {
    test('quality tier boundaries', () {
      expect(RarityTier.fromAnswerQuality(20), RarityTier.common);
      expect(RarityTier.fromAnswerQuality(40), RarityTier.rare);
      expect(RarityTier.fromAnswerQuality(55), RarityTier.epic);
      expect(RarityTier.fromAnswerQuality(70), RarityTier.legendary);
      expect(RarityTier.fromAnswerQuality(85), RarityTier.mythic);
    });
  });

  group('ScoringEngine', () {
    test('speed bonus tiers v2', () {
      expect(ScoringEngine.speedBonus(20000), 1.25);
      expect(ScoringEngine.speedBonus(45000), 1.10);
      expect(ScoringEngine.speedBonus(90000), 1.0);
      expect(ScoringEngine.speedBonus(150000), 0.90);
    });

    test('obscure fast pick scores higher than common slow pick', () {
      final obscure = ScoringEngine.calculateCellScore(
        usagePercentage: 5,
        obscurityScore: 90,
        responseTimeMs: 20000,
        mistakesOnCell: 0,
      );
      final common = ScoringEngine.calculateCellScore(
        usagePercentage: 90,
        obscurityScore: 15,
        responseTimeMs: 90000,
        mistakesOnCell: 0,
      );
      expect(obscure, greaterThan(common));
    });

    test('weighted hints cost more than flat legacy penalty for deep hints', () {
      expect(ScoringEngine.hintPenaltyForType('career_club'), greaterThan(GameConstants.hintScorePenalty));
      expect(ScoringEngine.hintPenaltyForType('nationality'), lessThan(GameConstants.hintScorePenalty + 1));
    });

    test('pace multiplier rewards sub-6-minute finishes', () {
      expect(ScoringEngine.paceMultiplier(5 * 60000), greaterThan(1.0));
      expect(ScoringEngine.paceMultiplier(20 * 60000), lessThan(1.0));
    });

    test('session score applies pace and weighted hints', () {
      final score = ScoringEngine.calculateSessionScore(
        cellScores: [12, 12, 12],
        hintsUsed: 1,
        hintPenaltySum: 9,
        mistakes: 0,
        completionBonus: GameConstants.dailyCompletionBonus,
        totalDurationMs: 5 * 60000,
      );
      final raw = 36 + GameConstants.dailyCompletionBonus - 9;
      expect(score, closeTo(raw * ScoringEngine.paceMultiplier(5 * 60000), 0.01));
    });
  });
}
