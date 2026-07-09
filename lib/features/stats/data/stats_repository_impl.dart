import '../../../core/cache/offline_cache.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';
import '../domain/stats.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl({
    required OfflineCache cache,
    ApiHttpClient? httpClient,
  })  : _cache = cache,
        _http = httpClient ?? ApiHttpClient();

  final OfflineCache _cache;
  final ApiHttpClient _http;

  @override
  Future<UserStats> getStats(String userUuid) async {
    try {
      final json = await _http.getJson(
        'stats',
        query: {'user_uuid': userUuid},
        headers: ApiConfig.userHeaders(userUuid),
        throwOnError: false,
      );
      if (json.isNotEmpty && json.containsKey('games_played')) {
        final stats = UserStats.fromJson(json);
        await _cache.cacheStats(stats.toJson());
        return stats;
      }
    } catch (_) {}

    final cached = await _cache.getStats();
    if (cached != null) return UserStats.fromJson(cached);
    return const UserStats();
  }
}
