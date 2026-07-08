import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/cache/offline_cache.dart';
import '../../../core/config/app_config.dart';
import '../domain/stats.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl({
    required OfflineCache cache,
    http.Client? httpClient,
  })  : _cache = cache,
        _http = httpClient ?? http.Client();

  final OfflineCache _cache;
  final http.Client _http;

  @override
  Future<UserStats> getStats(String userUuid) async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/stats')
            .replace(queryParameters: {'user_uuid': userUuid});
        final response = await _http.get(
          uri,
          headers: {
            ...AppConfig.supabaseFunctionHeaders,
            'x-user-uuid': userUuid,
          },
        );
        if (response.statusCode == 200) {
          final stats = UserStats.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
          await _cache.cacheStats(stats.toJson());
          return stats;
        }
      } catch (_) {}
    }

    final cached = await _cache.getStats();
    if (cached != null) return UserStats.fromJson(cached);
    return const UserStats();
  }
}
