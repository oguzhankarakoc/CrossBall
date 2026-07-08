import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crossball/core/cache/daily_completion_store.dart';
import 'package:crossball/core/utils/daily_puzzle_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyCompletionStore', () {
    test('marks and reads today UTC date per user', () async {
      SharedPreferences.setMockInitialValues({});
      final store = DailyCompletionStore();
      const userUuid = 'user-a';

      expect(await store.isCompletedToday(userUuid: userUuid), isFalse);

      await store.markCompletedToday(userUuid: userUuid);
      expect(await store.isCompletedToday(userUuid: userUuid), isTrue);
      expect(
        await store.isCompletedToday(userUuid: 'user-b'),
        isFalse,
      );
    });

    test('clearForUser removes guard', () async {
      SharedPreferences.setMockInitialValues({});
      final store = DailyCompletionStore();
      const userUuid = 'user-a';

      await store.markCompletedToday(userUuid: userUuid);
      await store.clearForUser(userUuid: userUuid);
      expect(await store.isCompletedToday(userUuid: userUuid), isFalse);
    });

    test('uses UTC puzzle date key', () async {
      SharedPreferences.setMockInitialValues({});
      final store = DailyCompletionStore();
      final today = DailyPuzzleSchedule.todayPuzzleDateUtc();

      await store.markCompletedToday(userUuid: 'u1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('daily_completed_date_v1_u1'), today);
    });
  });
}
