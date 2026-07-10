import '../../../core/cache/offline_cache.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';
import '../domain/club_mastery.dart';
import '../domain/player_mission.dart';
import '../domain/player_progression.dart';
import '../domain/season_info.dart';

class EconomyRepositoryImpl implements EconomyRepository {
  EconomyRepositoryImpl({
    required OfflineCache cache,
    ApiHttpClient? httpClient,
  })  : _cache = cache,
        _http = httpClient ?? ApiHttpClient();

  final OfflineCache _cache;
  final ApiHttpClient _http;

  @override
  Future<PlayerProgression> getProgression(String userUuid) async {
    final payload = await _fetchProfile(userUuid);
    final fromApi = _tryParseProgression(payload);
    if (fromApi != null) return fromApi;

    final cached = await _cache.getProgression();
    final fromCache = _tryParseProgression(cached, requireOk: false);
    if (fromCache != null) return fromCache;
    return const PlayerProgression();
  }

  /// Parses progression from economy-profile or a partial complete-session cache.
  PlayerProgression? _tryParseProgression(
    Map<String, dynamic>? json, {
    bool requireOk = true,
  }) {
    if (json == null || json.isEmpty) return null;
    if (requireOk && json['ok'] != true) return null;
    if (!requireOk && json['ok'] == false) return null;
    if (!json.containsKey('current_level') && !json.containsKey('experience_points')) {
      return null;
    }
    try {
      return PlayerProgression.fromJson(json);
    } catch (_) {
      return null;
    }
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
    try {
      final json = await _http.getJson(
        'season',
        query: {'user_uuid': userUuid},
        headers: ApiConfig.userHeaders(userUuid),
        throwOnError: false,
      );
      if (json['ok'] == true) return SeasonInfo.fromJson(json);
    } catch (_) {}
    return const SeasonInfo(slug: '', label: '');
  }

  @override
  Future<List<ClubMasteryEntry>> getClubMastery(String userUuid, {int limit = 12}) async {
    try {
      final json = await _http.getJson(
        'club-mastery',
        query: {'user_uuid': userUuid, 'limit': '$limit'},
        headers: ApiConfig.userHeaders(userUuid),
        throwOnError: false,
      );
      if (json['ok'] == true) {
        final clubs = json['clubs'] as List<dynamic>? ?? [];
        return clubs
            .map((e) => ClubMasteryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
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
    try {
      final json = await _http.getJson(
        'economy-profile',
        query: {'user_uuid': userUuid},
        headers: ApiConfig.userHeaders(userUuid),
        throwOnError: false,
      );
      if (json['ok'] == true) {
        await _cache.cacheProgression(json);
        return json;
      }
    } catch (_) {}
    return null;
  }
}
