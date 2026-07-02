import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crossball/core/cache/offline_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineCache', () {
    late OfflineCache cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cache = OfflineCache(prefs: prefs);
    });

    test('cache and retrieve daily puzzle', () async {
      final puzzle = {
        'puzzle_id': 'test-123',
        'date': DateTime.now().toIso8601String().split('T').first,
        'grid_size': 3,
        'row_clubs': [],
        'col_clubs': [],
        'cells': [],
      };

      await cache.cacheDailyPuzzle(puzzle);
      final retrieved = await cache.getDailyPuzzle();
      expect(retrieved, isNotNull);
      expect(retrieved!['puzzle_id'], 'test-123');
    });

    test('recent picks maintain order and limit', () async {
      for (var i = 0; i < 15; i++) {
        await cache.addRecentPick({'id': 'p$i', 'name': 'Player $i'});
      }
      final picks = await cache.getRecentPicks();
      expect(picks.length, lessThanOrEqualTo(10));
      expect(picks.first['id'], 'p14');
    });

    test('pending answers queue and flush', () async {
      await cache.queuePendingAnswer({'session_id': 's1', 'score': 100});
      await cache.queuePendingAnswer({'session_id': 's2', 'score': 200});
      final flushed = await cache.flushPendingAnswers();
      expect(flushed.length, 2);
      final again = await cache.flushPendingAnswers();
      expect(again, isEmpty);
    });
  });
}
