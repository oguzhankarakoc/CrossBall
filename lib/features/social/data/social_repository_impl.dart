import '../../../core/network/api_http_client.dart';
import '../domain/social.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl({ApiHttpClient? httpClient})
      : _http = httpClient ?? ApiHttpClient();

  final ApiHttpClient _http;

  @override
  Future<List<ActivityEvent>> getActivityFeed({int limit = 15}) async {
    try {
      final json = await _http.getJson(
        'activity-feed',
        query: {'limit': '$limit'},
        throwOnError: false,
      );
      if (json['ok'] == true) {
        final events = json['events'] as List<dynamic>? ?? [];
        return events
            .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<FootballFact> getFootballFact({
    required String locale,
    String context = 'intersection',
  }) async {
    try {
      final json = await _http.getJson(
        'player-fact',
        query: {'locale': locale, 'context': context},
        throwOnError: false,
      );
      if (json['ok'] == true) return FootballFact.fromJson(json);
    } catch (_) {}
    return const FootballFact(factKey: '', text: '');
  }

  @override
  Future<TournamentSnapshot> getTournament({
    required String userUuid,
    int limit = 25,
  }) async {
    try {
      final json = await _http.getJson(
        'tournament',
        query: {'user_uuid': userUuid, 'limit': '$limit'},
        headers: {'x-user-uuid': userUuid},
        throwOnError: false,
      );
      if (json['ok'] == true) return TournamentSnapshot.fromJson(json);
    } catch (_) {}
    return const TournamentSnapshot();
  }

  @override
  Future<CareerTimeline> getCareerTimeline({
    required String playerId,
    required String rowClubId,
    required String colClubId,
  }) async {
    try {
      final json = await _http.getJson(
        'career-timeline',
        query: {
          'player_id': playerId,
          'row_club_id': rowClubId,
          'col_club_id': colClubId,
        },
        throwOnError: false,
      );
      if (json['ok'] == true) return CareerTimeline.fromJson(json);
    } catch (_) {}
    return const CareerTimeline(playerName: 'Player', entries: []);
  }
}
