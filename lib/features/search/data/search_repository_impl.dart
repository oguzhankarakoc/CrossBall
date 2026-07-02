import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/cache/offline_cache.dart';
import '../../../core/utils/string_normalizer.dart';
import '../domain/search.dart';

class SearchApiService {
  SearchApiService({SupabaseClient? client, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<SearchResponse> search(String query, {int limit = 20}) async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/search-players')
            .replace(queryParameters: {'q': query, 'limit': limit.toString()});
        final response = await _http.get(
          uri,
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          return SearchResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }
    return SearchResponse(results: _demoSearch(query), latencyMs: 12);
  }

  List<Player> _demoSearch(String query) {
    const demoPlayers = [
      Player(id: 'pedro', name: 'Pedro', nationalityCode: 'ES', primaryPosition: 'Forward'),
      Player(id: 'deco', name: 'Deco', nationalityCode: 'PT', primaryPosition: 'Midfielder'),
      Player(id: 'fabregas', name: 'Cesc Fabregas', nationalityCode: 'ES', primaryPosition: 'Midfielder'),
      Player(id: 'etoo', name: "Samuel Eto'o", nationalityCode: 'CM', primaryPosition: 'Forward'),
      Player(id: 'ozil', name: 'Mesut Özil', nationalityCode: 'DE', primaryPosition: 'Midfielder'),
      Player(id: 'modric', name: 'Luka Modric', nationalityCode: 'HR', primaryPosition: 'Midfielder'),
      Player(id: 'ronaldo', name: 'Cristiano Ronaldo', nationalityCode: 'PT', primaryPosition: 'Forward'),
      Player(id: 'messi', name: 'Lionel Messi', nationalityCode: 'AR', primaryPosition: 'Forward'),
    ];

    if (query.isEmpty) return demoPlayers.take(5).toList();

    return demoPlayers
        .where((p) => StringNormalizer.fuzzyMatch(query, p.name))
        .toList();
  }
}

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({
    required SearchApiService api,
    required OfflineCache cache,
  })  : _api = api,
        _cache = cache;

  final SearchApiService _api;
  final OfflineCache _cache;

  @override
  Future<SearchResponse> search(String query, {int limit = 20}) =>
      _api.search(query, limit: limit);

  @override
  Future<List<Player>> getRecentPicks() async {
    final raw = await _cache.getRecentPicks();
    return raw.map(Player.fromJson).toList();
  }

  @override
  Future<List<Player>> getPopularPicks({int limit = 10}) async {
    final response = await _api.search('', limit: limit);
    return response.results;
  }

  @override
  Future<void> recordPick(Player player) async {
    await _cache.addRecentPick(player.toJson());
  }
}
