import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/cache/offline_cache.dart';
import '../../../core/config/app_config.dart';
import '../domain/club_mastery.dart';
import '../domain/player_mission.dart';
import '../domain/player_progression.dart';
import '../domain/season_info.dart';

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
    final payload = await _fetchProfile(userUuid);
    if (payload != null && payload['ok'] == true) {
      return PlayerProgression.fromJson(payload);
    }

    final cached = await _cache.getProgression();
    if (cached != null) return PlayerProgression.fromJson(cached);
    return const PlayerProgression();
  }

  @override
  Future<List<PlayerMission>> getMissions(String userUuid) async {
    final payload = await _fetchProfile(userUuid);
    if (payload != null && payload['ok'] == true) {
      final missionsRaw = payload['missions'] as List<dynamic>? ?? [];
      return missionsRaw
          .map((e) => PlayerMission.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  @override
  Future<SeasonInfo> getSeason(String userUuid) async {
    if (!AppConfig.isSupabaseConfigured) return const SeasonInfo(slug: '', label: '');

    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/season')
          .replace(queryParameters: {'user_uuid': userUuid});
      final response = await _http.get(
        uri,
        headers: {
          ...AppConfig.supabaseFunctionHeaders,
          'x-user-uuid': userUuid,
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true) return SeasonInfo.fromJson(json);
      }
    } catch (_) {}
    return const SeasonInfo(slug: '', label: '');
  }

  @override
  Future<List<ClubMasteryEntry>> getClubMastery(String userUuid, {int limit = 12}) async {
    if (!AppConfig.isSupabaseConfigured) return const [];

    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/club-mastery')
          .replace(queryParameters: {'user_uuid': userUuid, 'limit': '$limit'});
      final response = await _http.get(
        uri,
        headers: {
          ...AppConfig.supabaseFunctionHeaders,
          'x-user-uuid': userUuid,
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true) {
          final clubs = json['clubs'] as List<dynamic>? ?? [];
          return clubs
              .map((e) => ClubMasteryEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<bool> careerHintTasteAvailable(String userUuid) async {
    final payload = await _fetchProfile(userUuid);
    if (payload != null && payload['ok'] == true) {
      return payload['career_hint_taste_available'] as bool? ?? false;
    }
    return false;
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userUuid) async {
    if (!AppConfig.isSupabaseConfigured) return null;

    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/economy-profile')
          .replace(queryParameters: {'user_uuid': userUuid});
      final response = await _http.get(
        uri,
        headers: {
          ...AppConfig.supabaseFunctionHeaders,
          'x-user-uuid': userUuid,
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true) {
          await _cache.cacheProgression(json);
          return json;
        }
      }
    } catch (_) {}
    return null;
  }
}
