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

    test('recent picks are retired and legacy cache is cleared', () async {
      SharedPreferences.setMockInitialValues({
        'cache_recent_picks': '[{"id":"p1","name":"Player 1"}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final legacyCache = OfflineCache(prefs: prefs);
      final picks = await legacyCache.getRecentPicks();
      expect(picks, isEmpty);
      expect(prefs.getString('cache_recent_picks'), isNull);
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
