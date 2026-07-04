import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/social.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Map<String, String> get _headers => {
        'apikey': AppConfig.supabaseAnonKey,
      };

  @override
  Future<List<ActivityEvent>> getActivityFeed({int limit = 15}) async {
    if (!AppConfig.isSupabaseConfigured) return const [];

    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/activity-feed')
          .replace(queryParameters: {'limit': '$limit'});
      final response = await _http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true) {
          final events = json['events'] as List<dynamic>? ?? [];
          return events
              .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<FootballFact> getFootballFact({
    required String locale,
    String context = 'intersection',
  }) async {
    if (!AppConfig.isSupabaseConfigured) return const FootballFact(factKey: '', text: '');

    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/player-fact')
          .replace(queryParameters: {'locale': locale, 'context': context});
      final response = await _http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true) return FootballFact.fromJson(json);
      }
    } catch (_) {}
    return const FootballFact(factKey: '', text: '');
  }

  @override
  Future<TournamentSnapshot> getTournament({
    required String userUuid,
    int limit = 25,
  }) async {
    if (!AppConfig.isSupabaseConfigured) return const TournamentSnapshot();

    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/tournament')
          .replace(queryParameters: {'user_uuid': userUuid, 'limit': '$limit'});
      final response = await _http.get(
        uri,
        headers: {..._headers, 'x-user-uuid': userUuid},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true) return TournamentSnapshot.fromJson(json);
      }
    } catch (_) {}
    return const TournamentSnapshot();
  }

  @override
  Future<CareerTimeline> getCareerTimeline({
    required String playerId,
    required String rowClubId,
    required String colClubId,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      return const CareerTimeline(playerName: 'Player', entries: []);
    }

    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/career-timeline')
          .replace(queryParameters: {
        'player_id': playerId,
        'row_club_id': rowClubId,
        'col_club_id': colClubId,
      });
      final response = await _http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true) return CareerTimeline.fromJson(json);
      }
    } catch (_) {}
    return const CareerTimeline(playerName: 'Player', entries: []);
  }
}
