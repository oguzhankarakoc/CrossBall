import 'package:crossball/features/liveops/domain/liveops_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveOpsSnapshot', () {
    test('fromJson parses snapshot with feature flags and events', () {
      final snapshot = LiveOpsSnapshot.fromJson({
        'ok': true,
        'config': {
          'gameplay': {'available_modes': ['daily', 'practice']},
        },
        'feature_flags': {
          'friend_challenges': false,
          'statistics': true,
        },
        'active_events': [
          {
            'slug': 'ucl_week',
            'event_type': 'limited',
            'title': 'UCL Week',
            'description': 'Special puzzles',
          },
        ],
        'announcements': [
          {
            'slug': 'welcome',
            'type': 'feature',
            'title': 'Hello',
            'body': 'Welcome',
            'priority': 5,
          },
        ],
        'community_goals': [
          {
            'slug': 'global_1m',
            'title': '1M Puzzles',
            'description': 'Community goal',
            'target_value': 1000000,
            'current_value': 50000,
            'progress_pct': 5.0,
          },
        ],
        'cache_ttl_seconds': 300,
      });

      expect(snapshot.isFeatureEnabled('friend_challenges'), isFalse);
      expect(snapshot.isFeatureEnabled('statistics'), isTrue);
      expect(snapshot.activeEvents, hasLength(1));
      expect(snapshot.announcements.first.title, 'Hello');
      expect(snapshot.communityGoals.first.progressPct, 5.0);
    });

    test('fallback enables core features offline', () {
      final snapshot = LiveOpsSnapshot.fallback();
      expect(snapshot.isFeatureEnabled('friend_challenges'), isTrue);
      expect(snapshot.canStartNewSessions, isTrue);
      expect(snapshot.isMaintenanceMode, isFalse);
    });
  });
}
