import 'package:crossball/core/club_identity/club_display_resolver.dart';
import 'package:crossball/features/puzzle/domain/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Manchester United short label is Man United', () {
    const club = Club(
      id: '1',
      name: 'Manchester United',
      slug: 'manchester-united',
    );
    expect(club.shortLabel, 'Man United');
    expect(club.fullDisplayName, 'Manchester United');
  });

  test('DB short_name overrides registry', () {
    const club = Club(
      id: '2',
      name: 'FC Barcelona',
      slug: 'barcelona',
      shortName: 'Barça',
    );
    expect(club.shortLabel, 'Barça');
  });

  test('Bayern short label from registry', () {
    const club = Club(
      id: '3',
      name: 'Bayern Munich',
      slug: 'bayern-munich',
    );
    expect(club.shortLabel, 'Bayern');
    expect(ClubDisplayResolver.resolve(club).leagueName, 'Bundesliga');
  });

  test('short code prefers short_code field', () {
    const club = Club(
      id: '4',
      name: 'Real Madrid',
      slug: 'real-madrid',
      shortCode: 'RMA',
      badgeInitials: 'RM',
    );
    expect(club.code, 'RMA');
  });

  test('standalone club resolves slug from display name', () {
    final club = ClubDisplayResolver.standalone(
      id: 'uuid-1',
      name: 'Liverpool FC',
      shortName: 'Liverpool',
    );
    expect(club.slug, 'liverpool-fc');
    expect(club.shortLabel, 'Liverpool');
  });
}
