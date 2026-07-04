import 'package:crossball/shared/providers/practice_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first session of the day does not require ad', () {
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 0,
      dailyLimit: 5,
      isPremium: false,
    );
    expect(session.needsRewardedAdForNextSession, isFalse);
    expect(session.canStartSession, isTrue);
  });

  test('second free session requires rewarded ad', () {
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 1,
      dailyLimit: 5,
      isPremium: false,
    );
    expect(session.needsRewardedAdForNextSession, isTrue);
    expect(session.canStartSession, isFalse);
  });

  test('ad unlock allows next free session', () {
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 2,
      dailyLimit: 5,
      isPremium: false,
      adUnlockGranted: true,
    );
    expect(session.canStartSession, isTrue);
  });

  test('free daily limit is five sessions', () {
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 5,
      dailyLimit: 5,
      isPremium: false,
    );
    expect(session.hasReachedLimit, isTrue);
    expect(session.remaining, 0);
  });

  test('premium daily limit is ten sessions without ads', () {
    const session = PracticeSessionState(
      dateKey: '2026-07-04',
      completedToday: 3,
      dailyLimit: 10,
      isPremium: true,
    );
    expect(session.needsRewardedAdForNextSession, isFalse);
    expect(session.remaining, 7);
  });

  test('parses server quota payload', () {
    final session = PracticeSessionState.fromQuotaJson({
      'usage_date': '2026-07-04',
      'completed_today': 2,
      'daily_limit': 5,
      'is_premium': false,
      'ad_unlock_granted': true,
    });
    expect(session.completedToday, 2);
    expect(session.dailyLimit, 5);
    expect(session.adUnlockGranted, isTrue);
    expect(session.canStartSession, isTrue);
  });
}
