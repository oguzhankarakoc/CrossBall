import 'package:crossball/core/constants/game_constants.dart';
import 'package:crossball/shared/providers/practice_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('odd free sessions after an ad do not require another ad', () {
    // completed=1 → 2nd session of the day is free (every 2).
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 1,
      dailyLimit: GameConstants.practiceDailySoftCap,
      isPremium: false,
    );
    expect(session.needsRewardedAdForNextSession, isFalse);
    expect(session.canStartSession, isTrue);
  });

  test('even completed count requires rewarded ad for free users', () {
    for (final completed in [0, 2, 4]) {
      final session = PracticeSessionState(
        dateKey: '2026-07-04',
        completedToday: completed,
        dailyLimit: GameConstants.practiceDailySoftCap,
        isPremium: false,
      );
      expect(session.needsRewardedAdForNextSession, isTrue, reason: 'completed=$completed');
      expect(session.canStartSession, isFalse, reason: 'completed=$completed');
    }
  });

  test('ad unlock allows the gated free session', () {
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 2,
      dailyLimit: GameConstants.practiceDailySoftCap,
      isPremium: false,
      adUnlockGranted: true,
    );
    expect(session.needsRewardedAdForNextSession, isFalse);
    expect(session.canStartSession, isTrue);
  });

  test('premium never needs practice ads', () {
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 0,
      dailyLimit: GameConstants.practiceDailySoftCap,
      isPremium: true,
    );
    expect(session.needsRewardedAdForNextSession, isFalse);
    expect(session.canStartSession, isTrue);
  });

  test('parses server quota payload', () {
    final session = PracticeSessionState.fromQuotaJson({
      'usage_date': '2026-07-04',
      'completed_today': 2,
      'daily_limit': GameConstants.practiceDailySoftCap,
      'is_premium': false,
      'ad_unlock_granted': true,
    });
    expect(session.completedToday, 2);
    expect(session.adUnlockGranted, isTrue);
    expect(session.canStartSession, isTrue);
  });
}
