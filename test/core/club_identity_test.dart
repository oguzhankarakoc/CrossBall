import 'package:crossball/core/club_identity/club_identity.dart';
import 'package:crossball/core/club_identity/club_identity_registry.dart';
import 'package:crossball/features/puzzle/domain/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Barcelona resolves to abstract stripes identity', () {
    const club = Club(
      id: '1',
      name: 'FC Barcelona',
      slug: 'barcelona',
      badgePrimaryColor: '#A50044',
      badgeSecondaryColor: '#004D98',
      badgeInitials: 'BAR',
    );
    final identity = ClubIdentityRegistry.resolve(club);
    expect(identity.symbolType, ClubSymbolType.abstractStripes);
    expect(identity.shortCode, 'BAR');
  });

  test('Chelsea resolves to abstract lion-inspired identity', () {
    const club = Club(
      id: '2',
      name: 'Chelsea FC',
      slug: 'chelsea',
    );
    final identity = ClubIdentityRegistry.resolve(club);
    expect(identity.symbolType, ClubSymbolType.abstractLion);
    expect(identity.shortCode, 'CHE');
  });

  test('Liverpool resolves to abstract wings identity', () {
    const club = Club(
      id: '4',
      name: 'Liverpool FC',
      slug: 'liverpool-fc',
    );
    final identity = ClubIdentityRegistry.resolve(club);
    expect(identity.symbolType, ClubSymbolType.abstractWings);
    expect(identity.shortCode, 'LIV');
  });

  test('Unknown club gets deterministic fallback', () {
    const club = Club(id: '3', name: 'Test FC', slug: 'test-fc-unknown');
    final a = ClubIdentityRegistry.resolve(club);
    final b = ClubIdentityRegistry.resolve(club);
    expect(a.shortCode, isNotEmpty);
    expect(a.symbolType, isNotNull);
    expect(a.primaryColor, b.primaryColor);
  });

  test('All DB seed slugs have curated identity', () {
    const dbSlugs = [
      'barcelona', 'fc-barcelona', 'real-madrid', 'atletico-madrid', 'sevilla-fc',
      'valencia-cf', 'manchester-united', 'manchester-city', 'liverpool-fc', 'chelsea',
      'chelsea-fc', 'arsenal-fc', 'tottenham-hotspur', 'newcastle-united',
      'west-ham-united', 'aston-villa', 'everton-fc', 'bayern-munich',
      'borussia-dortmund', 'rb-leipzig', 'bayer-leverkusen', 'borussia-monchengladbach',
      'juventus', 'ac-milan', 'inter-milan', 'as-roma', 'napoli', 'lazio', 'fiorentina',
      'paris-saintgermain', 'psg', 'lyon', 'marseille', 'monaco', 'lille-osc', 'ajax',
      'psv-eindhoven', 'feyenoord', 'benfica', 'fc-porto', 'sporting-cp', 'celtic-fc',
      'rangers-fc', 'galatasaray', 'fenerbahce', 'besiktas', 'trabzonspor', 'river-plate',
      'boca-juniors', 'flamengo', 'palmeiras', 'santos-fc', 'corinthians', 'club-america',
      'monterrey', 'la-galaxy', 'inter-miami', 'al-hilal', 'al-nassr', 'al-ahli',
      'shakhtar-donetsk', 'dynamo-kyiv', 'red-star-belgrade', 'partizan', 'olympiacos',
      'panathinaikos', 'copenhagen', 'brondby', 'anderlecht', 'club-brugge', 'basel',
      'young-boys', 'salzburg', 'rapid-vienna', 'sparta-prague', 'slavia-prague',
      'legia-warsaw', 'steaua-bucharest', 'cfr-cluj', 'dinamo-zagreb', 'hajduk-split',
      'malmo-ff', 'aik', 'rosenborg', 'molde-fk', 'hjk-helsinki', 'qarabag-fk', 'apoel',
      'omonia', 'maccabi-tel-aviv', 'maccabi-haifa', 'sydney-fc', 'melbourne-city',
      'urawa-red-diamonds', 'kashima-antlers', 'guangzhou-fc', 'shanghai-sipg', 'ulsan-hd',
      'jeonbuk-hyundai', 'wydad-ac', 'raja-casablanca', 'esperance-tunis', 'al-ahly-cairo',
      'kaizer-chiefs', 'orlando-pirates',
    ];

    for (final slug in dbSlugs) {
      final club = Club(id: slug, name: slug, slug: slug);
      final identity = ClubIdentityRegistry.resolve(club);
      expect(
        identity.symbolType,
        isNot(ClubSymbolType.abstractShield),
        reason: '$slug should have curated symbol',
      );
    }
  });
}
