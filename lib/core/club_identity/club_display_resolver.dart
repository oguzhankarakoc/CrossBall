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
