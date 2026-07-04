import 'package:crossball/features/economy/domain/season_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SeasonInfo parses reward tiers from economy payload', () {
    final season = SeasonInfo.fromJson({
      'ok': true,
      'slug': '2026-s1',
      'label': 'Season 1',
      'starts_at': '2026-01-01T00:00:00Z',
      'ends_at': '2026-06-30T23:59:59Z',
      'season_points': 250,
      'reward_tiers': {
        'tiers': [
          {'points': 100, 'reward': 'badge'},
          {'points': 500, 'reward': 'frame'},
        ],
      },
    });

    expect(season.isActive, isTrue);
    expect(season.seasonPoints, 250);
    expect(season.rewardTiers, hasLength(2));
    expect(season.rewardTiers.first.points, 100);
  });

  test('inactive season has empty slug', () {
    const season = SeasonInfo(slug: '', label: '');
    expect(season.isActive, isFalse);
  });
}
