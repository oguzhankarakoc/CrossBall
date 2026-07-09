import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';
import '../domain/leaderboard.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl({ApiHttpClient? httpClient})
      : _http = httpClient ?? ApiHttpClient();

  final ApiHttpClient _http;

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({String? league, int limit = 50}) async {
    try {
      final params = <String, String>{'limit': '$limit', 'type': 'rating'};
      if (league != null && league.isNotEmpty) params['league'] = league;

      final json = await _http.getJson('leaderboard', query: params, throwOnError: false);
      if (json['ok'] != true) return const [];

      final entries = json['entries'] as List<dynamic>? ?? [];
      return entries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<WeeklyDailyLeaderboardSnapshot?> getWeeklyDailyLeaderboard({
    String? userUuid,
    int limit = 50,
  }) async {
    try {
      final params = <String, String>{'limit': '$limit', 'type': 'weekly_daily'};
      final headers = <String, String>{};
      if (userUuid != null && userUuid.isNotEmpty) {
        params['user_uuid'] = userUuid;
        headers.addAll(ApiConfig.userHeaders(userUuid));
      }

      final json = await _http.getJson(
        'leaderboard',
        query: params,
        headers: headers.isEmpty ? null : headers,
        throwOnError: false,
      );
      if (json['ok'] != true) return null;
      return WeeklyDailyLeaderboardSnapshot.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
