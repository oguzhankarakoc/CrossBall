import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/cache/offline_cache.dart';
import '../../../core/config/app_config.dart';
import '../domain/player_progression.dart';

class EconomyRepositoryImpl implements EconomyRepository {
  EconomyRepositoryImpl({
    required OfflineCache cache,
    http.Client? httpClient,
  })  : _cache = cache,
        _http = httpClient ?? http.Client();

  final OfflineCache _cache;
  final http.Client _http;

  @override
  Future<PlayerProgression> getProgression(String userUuid) async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/economy-profile')
            .replace(queryParameters: {'user_uuid': userUuid});
        final response = await _http.get(
          uri,
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'x-user-uuid': userUuid,
          },
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          if (json['ok'] == true) {
            final progression = PlayerProgression.fromJson(json);
            await _cache.cacheProgression(progression.toJson());
            return progression;
          }
        }
      } catch (_) {}
    }

    final cached = await _cache.getProgression();
    if (cached != null) return PlayerProgression.fromJson(cached);
    return const PlayerProgression();
  }
}
