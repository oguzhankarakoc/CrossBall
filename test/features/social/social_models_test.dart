import 'package:crossball/features/social/domain/social.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ActivityEvent parses feed payload', () {
    final event = ActivityEvent.fromJson({
      'id': 'abc',
      'display_name': 'Oğuz',
      'event_type': 'daily_completed',
      'payload': {'final_score': 420},
      'created_at': '2026-07-04T12:00:00Z',
    });

    expect(event.displayName, 'Oğuz');
    expect(event.payload['final_score'], 420);
  });

  test('TournamentSnapshot parses leaderboard payload', () {
    final snapshot = TournamentSnapshot.fromJson({
      'ok': true,
      'slug': 'weekly-tournament',
      'title': 'Weekly Tournament',
      'entries': [
        {
          'rank': 1,
          'display_name': 'Ace',
          'best_score': 900,
          'sessions_count': 3,
        },
      ],
      'user_rank': 2,
    });

    expect(snapshot.isActive, isTrue);
    expect(snapshot.entries.first.bestScore, 900);
    expect(snapshot.userRank, 2);
  });

  test('CareerTimelineEntry formats open-ended years', () {
    const entry = CareerTimelineEntry(
      clubName: 'Arsenal',
      startYear: 2010,
      highlight: true,
    );

    expect(entry.yearLabel('Present'), '2010–Present');
  });
}
