import 'package:crossball/features/economy/domain/player_mission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerMission', () {
    test('fromJson parses progress fields', () {
      final mission = PlayerMission.fromJson({
        'slug': 'daily_play_one',
        'title': 'Daily Player',
        'description': 'Complete one daily',
        'period': 'daily',
        'progress_current': 0,
        'progress_target': 1,
        'is_completed': false,
        'reward_xp': 75,
      });

      expect(mission.slug, 'daily_play_one');
      expect(mission.progressFraction, 0);
      expect(mission.rewardXp, 75);
    });

    test('progressFraction is 1 when completed', () {
      const mission = PlayerMission(
        slug: 'daily_play_one',
        title: 'Daily',
        description: 'Desc',
        period: 'daily',
        progressCurrent: 1,
        progressTarget: 1,
        isCompleted: true,
      );

      expect(mission.progressFraction, 1);
    });
  });
}
