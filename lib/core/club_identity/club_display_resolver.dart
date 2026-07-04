import '../../features/puzzle/domain/puzzle.dart';

/// Human-readable club labels + league hints for puzzle headers.
abstract final class ClubDisplayResolver {
  static const Map<String, ClubDisplayInfo> _bySlug = {
    'barcelona': ClubDisplayInfo('FC Barcelona', 'Barcelona', 'La Liga', countryCode: 'ES'),
    'fc-barcelona': ClubDisplayInfo('FC Barcelona', 'Barcelona', 'La Liga', countryCode: 'ES'),
    'real-madrid': ClubDisplayInfo('Real Madrid CF', 'Real Madrid', 'La Liga', countryCode: 'ES'),
    'atletico-madrid': ClubDisplayInfo('Atlético Madrid', 'Atletico', 'La Liga', countryCode: 'ES'),
    'sevilla-fc': ClubDisplayInfo('Sevilla FC', 'Sevilla', 'La Liga', countryCode: 'ES'),
    'valencia-cf': ClubDisplayInfo('Valencia CF', 'Valencia', 'La Liga', countryCode: 'ES'),
    'chelsea': ClubDisplayInfo('Chelsea FC', 'Chelsea', 'Premier League', countryCode: 'GB'),
    'chelsea-fc': ClubDisplayInfo('Chelsea FC', 'Chelsea', 'Premier League', countryCode: 'GB'),
    'manchester-united': ClubDisplayInfo('Manchester United', 'Man United', 'Premier League', countryCode: 'GB'),
    'manchester-city': ClubDisplayInfo('Manchester City', 'Man City', 'Premier League', countryCode: 'GB'),
    'liverpool-fc': ClubDisplayInfo('Liverpool FC', 'Liverpool', 'Premier League', countryCode: 'GB'),
    'arsenal-fc': ClubDisplayInfo('Arsenal FC', 'Arsenal', 'Premier League', countryCode: 'GB'),
    'tottenham-hotspur': ClubDisplayInfo('Tottenham Hotspur', 'Tottenham', 'Premier League', countryCode: 'GB'),
    'newcastle-united': ClubDisplayInfo('Newcastle United', 'Newcastle', 'Premier League', countryCode: 'GB'),
    'west-ham-united': ClubDisplayInfo('West Ham United', 'West Ham', 'Premier League', countryCode: 'GB'),
    'aston-villa': ClubDisplayInfo('Aston Villa', 'Aston Villa', 'Premier League', countryCode: 'GB'),
    'everton-fc': ClubDisplayInfo('Everton FC', 'Everton', 'Premier League', countryCode: 'GB'),
    'bayern-munich': ClubDisplayInfo('FC Bayern Munich', 'Bayern', 'Bundesliga', countryCode: 'DE'),
    'borussia-dortmund': ClubDisplayInfo('Borussia Dortmund', 'Dortmund', 'Bundesliga', countryCode: 'DE'),
    'rb-leipzig': ClubDisplayInfo('RB Leipzig', 'Leipzig', 'Bundesliga', countryCode: 'DE'),
    'bayer-leverkusen': ClubDisplayInfo('Bayer Leverkusen', 'Leverkusen', 'Bundesliga', countryCode: 'DE'),
    'borussia-monchengladbach': ClubDisplayInfo('Borussia Mönchengladbach', 'Gladbach', 'Bundesliga', countryCode: 'DE'),
    'juventus': ClubDisplayInfo('Juventus FC', 'Juventus', 'Serie A', countryCode: 'IT'),
    'ac-milan': ClubDisplayInfo('AC Milan', 'AC Milan', 'Serie A', countryCode: 'IT'),
    'inter-milan': ClubDisplayInfo('Inter Milan', 'Inter', 'Serie A', countryCode: 'IT'),
    'as-roma': ClubDisplayInfo('AS Roma', 'Roma', 'Serie A', countryCode: 'IT'),
    'napoli': ClubDisplayInfo('SSC Napoli', 'Napoli', 'Serie A', countryCode: 'IT'),
    'lazio': ClubDisplayInfo('SS Lazio', 'Lazio', 'Serie A', countryCode: 'IT'),
    'fiorentina': ClubDisplayInfo('ACF Fiorentina', 'Fiorentina', 'Serie A', countryCode: 'IT'),
    'psg': ClubDisplayInfo('Paris Saint-Germain', 'PSG', 'Ligue 1', countryCode: 'FR'),
    'paris-saintgermain': ClubDisplayInfo('Paris Saint-Germain', 'PSG', 'Ligue 1', countryCode: 'FR'),
    'lyon': ClubDisplayInfo('Olympique Lyonnais', 'Lyon', 'Ligue 1', countryCode: 'FR'),
    'marseille': ClubDisplayInfo('Olympique Marseille', 'Marseille', 'Ligue 1', countryCode: 'FR'),
    'monaco': ClubDisplayInfo('AS Monaco', 'Monaco', 'Ligue 1', countryCode: 'FR'),
    'lille-osc': ClubDisplayInfo('Lille OSC', 'Lille', 'Ligue 1', countryCode: 'FR'),
    'galatasaray': ClubDisplayInfo('Galatasaray SK', 'Galatasaray', 'Süper Lig', countryCode: 'TR'),
    'fenerbahce': ClubDisplayInfo('Fenerbahçe SK', 'Fenerbahce', 'Süper Lig', countryCode: 'TR'),
    'besiktas': ClubDisplayInfo('Beşiktaş JK', 'Besiktas', 'Süper Lig', countryCode: 'TR'),
    'trabzonspor': ClubDisplayInfo('Trabzonspor', 'Trabzonspor', 'Süper Lig', countryCode: 'TR'),
    'ajax': ClubDisplayInfo('AFC Ajax', 'Ajax', 'Eredivisie', countryCode: 'NL'),
    'psv-eindhoven': ClubDisplayInfo('PSV Eindhoven', 'PSV', 'Eredivisie', countryCode: 'NL'),
    'feyenoord': ClubDisplayInfo('Feyenoord', 'Feyenoord', 'Eredivisie', countryCode: 'NL'),
    'benfica': ClubDisplayInfo('SL Benfica', 'Benfica', 'Primeira Liga', countryCode: 'PT'),
    'fc-porto': ClubDisplayInfo('FC Porto', 'Porto', 'Primeira Liga', countryCode: 'PT'),
    'sporting-cp': ClubDisplayInfo('Sporting CP', 'Sporting', 'Primeira Liga', countryCode: 'PT'),
    'celtic-fc': ClubDisplayInfo('Celtic FC', 'Celtic', 'Scottish Premiership', countryCode: 'GB'),
    'rangers-fc': ClubDisplayInfo('Rangers FC', 'Rangers', 'Scottish Premiership', countryCode: 'GB'),
    'aik': ClubDisplayInfo('AIK', 'AIK', 'Allsvenskan', countryCode: 'SE'),
    'anderlecht': ClubDisplayInfo('RSC Anderlecht', 'Anderlecht', 'Pro League', countryCode: 'BE'),
    'apoel': ClubDisplayInfo('APOEL FC', 'APOEL', 'Cypriot First Division', countryCode: 'CY'),
    'basel': ClubDisplayInfo('FC Basel', 'Basel', 'Super League', countryCode: 'CH'),
    'brondby': ClubDisplayInfo('Brøndby IF', 'Brondby', 'Superliga', countryCode: 'DK'),
    'cfr-cluj': ClubDisplayInfo('CFR Cluj', 'CFR Cluj', 'Liga I', countryCode: 'RO'),
    'club-america': ClubDisplayInfo('Club América', 'America', 'Liga MX', countryCode: 'MX'),
    'club-brugge': ClubDisplayInfo('Club Brugge', 'Club Brugge', 'Pro League', countryCode: 'BE'),
    'copenhagen': ClubDisplayInfo('FC Copenhagen', 'Copenhagen', 'Superliga', countryCode: 'DK'),
    'dinamo-zagreb': ClubDisplayInfo('Dinamo Zagreb', 'Dinamo', 'HNL', countryCode: 'HR'),
    'dynamo-kyiv': ClubDisplayInfo('Dynamo Kyiv', 'Dynamo Kyiv', 'Premier League', countryCode: 'UA'),
    'esperance-tunis': ClubDisplayInfo('Espérance de Tunis', 'Esperance', 'Ligue 1', countryCode: 'TN'),
    'guangzhou-fc': ClubDisplayInfo('Guangzhou FC', 'Guangzhou', 'CSL', countryCode: 'CN'),
    'hajduk-split': ClubDisplayInfo('Hajduk Split', 'Hajduk', 'HNL', countryCode: 'HR'),
    'hjk-helsinki': ClubDisplayInfo('HJK Helsinki', 'HJK', 'Veikkausliiga', countryCode: 'FI'),
    'jeonbuk-hyundai': ClubDisplayInfo('Jeonbuk Hyundai', 'Jeonbuk', 'K League', countryCode: 'KR'),
    'kaizer-chiefs': ClubDisplayInfo('Kaizer Chiefs', 'Kaizer', 'Premier Soccer League', countryCode: 'ZA'),
    'kashima-antlers': ClubDisplayInfo('Kashima Antlers', 'Kashima', 'J1 League', countryCode: 'JP'),
    'legia-warsaw': ClubDisplayInfo('Legia Warsaw', 'Legia', 'Ekstraklasa', countryCode: 'PL'),
    'maccabi-haifa': ClubDisplayInfo('Maccabi Haifa', 'M. Haifa', 'Ligat HaAl', countryCode: 'IL'),
    'maccabi-tel-aviv': ClubDisplayInfo('Maccabi Tel Aviv', 'M. Tel Aviv', 'Ligat HaAl', countryCode: 'IL'),
    'malmo-ff': ClubDisplayInfo('Malmö FF', 'Malmo', 'Allsvenskan', countryCode: 'SE'),
    'melbourne-city': ClubDisplayInfo('Melbourne City', 'Melbourne', 'A-League', countryCode: 'AU'),
    'molde-fk': ClubDisplayInfo('Molde FK', 'Molde', 'Eliteserien', countryCode: 'NO'),
    'monterrey': ClubDisplayInfo('CF Monterrey', 'Monterrey', 'Liga MX', countryCode: 'MX'),
    'olympiacos': ClubDisplayInfo('Olympiacos FC', 'Olympiacos', 'Super League', countryCode: 'GR'),
    'omonia': ClubDisplayInfo('AC Omonia', 'Omonia', 'Cypriot First Division', countryCode: 'CY'),
    'orlando-pirates': ClubDisplayInfo('Orlando Pirates', 'Pirates', 'Premier Soccer League', countryCode: 'ZA'),
    'panathinaikos': ClubDisplayInfo('Panathinaikos FC', 'Panathinaikos', 'Super League', countryCode: 'GR'),
    'partizan': ClubDisplayInfo('FK Partizan', 'Partizan', 'SuperLiga', countryCode: 'RS'),
    'qarabag-fk': ClubDisplayInfo('Qarabağ FK', 'Qarabag', 'Premier League', countryCode: 'AZ'),
    'raja-casablanca': ClubDisplayInfo('Raja CA', 'Raja', 'Botola', countryCode: 'MA'),
    'rapid-vienna': ClubDisplayInfo('SK Rapid Wien', 'Rapid', 'Bundesliga', countryCode: 'AT'),
    'red-star-belgrade': ClubDisplayInfo('Red Star Belgrade', 'Red Star', 'SuperLiga', countryCode: 'RS'),
    'rosenborg': ClubDisplayInfo('Rosenborg BK', 'Rosenborg', 'Eliteserien', countryCode: 'NO'),
    'salzburg': ClubDisplayInfo('FC Salzburg', 'Salzburg', 'Bundesliga', countryCode: 'AT'),
    'shakhtar-donetsk': ClubDisplayInfo('Shakhtar Donetsk', 'Shakhtar', 'Premier League', countryCode: 'UA'),
    'shanghai-sipg': ClubDisplayInfo('Shanghai Port', 'SIPG', 'CSL', countryCode: 'CN'),
    'slavia-prague': ClubDisplayInfo('Slavia Prague', 'Slavia', 'Fortuna Liga', countryCode: 'CZ'),
    'sparta-prague': ClubDisplayInfo('Sparta Prague', 'Sparta', 'Fortuna Liga', countryCode: 'CZ'),
    'steaua-bucharest': ClubDisplayInfo('FCSB', 'Steaua', 'Liga I', countryCode: 'RO'),
    'sydney-fc': ClubDisplayInfo('Sydney FC', 'Sydney', 'A-League', countryCode: 'AU'),
    'ulsan-hd': ClubDisplayInfo('Ulsan HD', 'Ulsan', 'K League', countryCode: 'KR'),
    'urawa-red-diamonds': ClubDisplayInfo('Urawa Red Diamonds', 'Urawa', 'J1 League', countryCode: 'JP'),
    'wydad-ac': ClubDisplayInfo('Wydad AC', 'Wydad', 'Botola', countryCode: 'MA'),
    'young-boys': ClubDisplayInfo('Young Boys', 'Young Boys', 'Super League', countryCode: 'CH'),
  };

  static const Map<String, String> _countryNames = {
    'ES': 'Spain',
    'GB': 'England',
    'DE': 'Germany',
    'IT': 'Italy',
    'FR': 'France',
    'TR': 'Turkey',
    'NL': 'Netherlands',
    'PT': 'Portugal',
    'AR': 'Argentina',
    'BR': 'Brazil',
    'US': 'United States',
    'SA': 'Saudi Arabia',
    'SE': 'Sweden',
    'BE': 'Belgium',
    'CY': 'Cyprus',
    'CH': 'Switzerland',
    'DK': 'Denmark',
    'RO': 'Romania',
    'MX': 'Mexico',
    'HR': 'Croatia',
    'UA': 'Ukraine',
    'TN': 'Tunisia',
    'CN': 'China',
    'FI': 'Finland',
    'KR': 'South Korea',
    'ZA': 'South Africa',
    'JP': 'Japan',
    'PL': 'Poland',
    'IL': 'Israel',
    'AU': 'Australia',
    'NO': 'Norway',
    'GR': 'Greece',
    'RS': 'Serbia',
    'AZ': 'Azerbaijan',
    'MA': 'Morocco',
    'AT': 'Austria',
    'CZ': 'Czech Republic',
    'EG': 'Egypt',
  };

  static ClubDisplayInfo resolve(Club club) {
    final slug = club.slug.toLowerCase();
    final known = _bySlug[slug];

    return ClubDisplayInfo(
      club.displayName ?? known?.displayName ?? club.name,
      club.shortName ?? known?.shortLabel ?? _deriveShortLabel(club.name),
      club.leagueName ?? known?.leagueName,
      countryCode: club.countryCode ?? known?.countryCode,
    );
  }

  static String shortCode(Club club) =>
      club.shortCode ?? club.badgeInitials ?? club.slug.substring(0, 3).toUpperCase();

  static String countryName(Club club) {
    final code = club.countryCode;
    if (code == null || code.isEmpty) return '';
    return _countryNames[code.toUpperCase()] ?? code;
  }

  /// Builds a [Club] for list UIs when only id + display names are available.
  static Club standalone({
    required String id,
    required String name,
    String? shortName,
  }) {
    final slug = _slugForName(name, shortName) ?? _slugify(name);
    final known = _bySlug[slug];
    return Club(
      id: id,
      name: name,
      slug: slug,
      displayName: name,
      shortName: shortName,
      countryCode: known?.countryCode,
      leagueName: known?.leagueName,
    );
  }

  static String? _slugForName(String name, String? shortName) {
    final nameLower = name.toLowerCase();
    final shortLower = (shortName ?? '').toLowerCase();
    for (final entry in _bySlug.entries) {
      final info = entry.value;
      if (info.displayName.toLowerCase() == nameLower ||
          info.shortLabel.toLowerCase() == nameLower ||
          (shortLower.isNotEmpty && info.shortLabel.toLowerCase() == shortLower)) {
        return entry.key;
      }
    }
    return null;
  }

  static String _slugify(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  static String _deriveShortLabel(String fullName) {
    var name = fullName.trim();
    name = name.replaceAll(RegExp(r'\s+'), ' ');

    if (name.startsWith('Manchester ')) {
      return 'Man ${name.substring('Manchester '.length)}';
    }
    if (name.contains('Bayern')) return 'Bayern';
    if (name.startsWith('FC ')) return name.substring(3);
    if (name.startsWith('AC ')) return name.substring(3);
    if (name.endsWith(' FC')) return name.substring(0, name.length - 3);
    if (name.endsWith(' CF')) return name.substring(0, name.length - 3);

    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length <= 2) return name;
    return parts.first;
  }
}

class ClubDisplayInfo {
  const ClubDisplayInfo(
    this.displayName,
    this.shortLabel,
    this.leagueName, {
    this.countryCode,
  });

  final String displayName;
  final String shortLabel;
  final String? leagueName;
  final String? countryCode;
}
