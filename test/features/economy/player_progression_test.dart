import 'package:crossball/features/economy/domain/player_progression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerProgression', () {
    test('fromJson parses economy profile response', () {
      final progression = PlayerProgression.fromJson({
        'experience_points': 1250,
        'current_level': 5,
        'xp_to_next_level': 350,
        'competitive_rating': 1425.5,
        'current_league': 'gold',
        'games_played': 12,
        'games_completed': 10,
        'games_won': 3,
        'current_streak': 4,
        'best_streak': 7,
        'highest_score': 890,
        'average_score': 620.5,
        'rare_answers_found': 8,
        'legendary_answers_found': 2,
        'perfect_games': 1,
        'season_points': 125,
        'achievement_points': 45,
        'achievements': [
          {
            'slug': 'first_puzzle',
            'title': 'First Steps',
            'description': 'Complete your first puzzle',
            'unlocked_at': '2026-07-01T10:00:00Z',
          },
        ],
      });

      expect(progression.experiencePoints, 1250);
      expect(progression.currentLevel, 5);
      expect(progression.competitiveRating, 1425.5);
      expect(progression.currentLeague, 'gold');
      expect(progression.achievements, hasLength(1));
      expect(progression.achievements.first.slug, 'first_puzzle');
    });

    test('defaults when fields missing', () {
      const progression = PlayerProgression();
      expect(progression.currentLevel, 1);
      expect(progression.competitiveRating, 1000);
      expect(progression.currentLeague, 'bronze');
    });

    test('fromJson accepts numeric doubles from JSON/Postgres NUMERIC', () {
      final progression = PlayerProgression.fromJson({
        'experience_points': 2720.0,
        'current_level': 7.0,
        'xp_to_next_level': 380.0,
        'competitive_rating': 1040.96,
        'current_league': 'bronze',
        'games_played': 25.0,
        'season_points': 246.0,
        'achievement_points': 45.0,
        'highest_score': 890.5,
        'average_score': 620.5,
        'achievements': [
          {
            'slug': 'first_puzzle',
            'title': null,
            'description': 'Complete your first puzzle',
            'unlocked_at': '2026-07-01T10:00:00Z',
          },
        ],
      });

      expect(progression.experiencePoints, 2720);
      expect(progression.currentLevel, 7);
      expect(progression.seasonPoints, 246);
      expect(progression.competitiveRating, closeTo(1040.96, 0.001));
      expect(progression.achievements, hasLength(1));
      expect(progression.achievements.first.title, '');
    });
  });
}
