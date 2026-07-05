import 'package:crossball/core/utils/daily_puzzle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('next reset is UTC midnight', () {
    final now = DateTime.utc(2026, 7, 5, 14, 30);
    final next = DailyPuzzleSchedule.nextResetUtc(now);
    expect(next, DateTime.utc(2026, 7, 6));
  });

  test('today puzzle date uses UTC calendar day', () {
    final now = DateTime.utc(2026, 7, 5, 23, 59);
    expect(DailyPuzzleSchedule.todayPuzzleDateUtc(now), '2026-07-05');
  });

  test('countdown formats hours and minutes', () {
    expect(
      DailyPuzzleSchedule.formatCountdown(const Duration(hours: 5, minutes: 12)),
      '5h 12m',
    );
    expect(DailyPuzzleSchedule.formatCountdown(const Duration(minutes: 45)), '45m');
  });

  test('elapsed formats minutes and seconds', () {
    expect(DailyPuzzleSchedule.formatElapsed(125), '2m 5s');
    expect(DailyPuzzleSchedule.formatElapsed(3720), '1h 02m');
  });

  test('rollout window follows UTC midnight', () {
    final justAfterMidnight = DateTime.utc(2026, 7, 5, 0, 10);
    final beforeMidnight = DateTime.utc(2026, 7, 4, 23, 50);
    expect(DailyPuzzleSchedule.isWithinRolloutWindow(justAfterMidnight), isTrue);
    expect(DailyPuzzleSchedule.isWithinRolloutWindow(beforeMidnight), isFalse);
  });
}
