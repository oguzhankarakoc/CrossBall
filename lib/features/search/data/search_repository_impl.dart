import '../../../core/cache/offline_cache.dart';
import '../../../core/network/api_http_client.dart';
import '../../../core/utils/string_normalizer.dart';
import '../domain/search.dart';

class SearchApiService {
  SearchApiService({ApiHttpClient? httpClient}) : _http = httpClient ?? ApiHttpClient();

  final ApiHttpClient _http;

  Future<SearchResponse> search(
    String query, {
    int limit = 20,
    SearchContext? context,
    bool competitive = false,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'limit': limit.toString(),
      };
      // Always send cell clubs so clubs_preview can prioritize the puzzle pair.
      // competitive=1 suppresses relevance ranking boost only; green badge still
      // comes from is_cell_relevant when the player validates for the cell.
      if (context?.rowClubId != null) {
        params['row_club_id'] = context!.rowClubId!;
      }
      if (context?.colClubId != null) {
        params['col_club_id'] = context!.colClubId!;
      }
      if (competitive) {
        params['competitive'] = '1';
      }

      final json = await _http.getJson(
        'search-players',
        query: params,
        throwOnError: false,
      );
      if (json.isNotEmpty) return SearchResponse.fromJson(json);
    } catch (_) {}
    return _demoSearch(query, context: context, limit: limit);
  }

  Future<List<Player>> getSuggested(SearchContext context, {int limit = 12}) async {
    try {
      final json = await _http.getJson(
        'search-players',
        query: {
          'q': '',
          'limit': '$limit',
          'mode': 'suggested',
          'row_club_id': context.rowClubId!,
          'col_club_id': context.colClubId!,
        },
        throwOnError: false,
      );
      if (json.isNotEmpty) {
        return (json['suggested'] as List<dynamic>? ?? json['results'] as List<dynamic>? ?? [])
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _demoSearch('', context: context, limit: limit).suggested;
  }

  SearchResponse _demoSearch(
    String query, {
    SearchContext? context,
    int limit = 20,
  }) {
    const demoPlayers = [
      Player(
        id: 'deco',
        name: 'Deco',
        nationalityCode: 'PT',
        primaryPosition: 'Attacking Midfield',
        clubsPreview: ['Barcelona', 'Chelsea', 'Porto'],
        popularityScore: 84,
        isCellRelevant: true,
      ),
      Player(
        id: 'fabregas',
        name: 'Cesc Fabregas',
        nationalityCode: 'ES',
        primaryPosition: 'Midfielder',
        clubsPreview: ['Arsenal', 'Barcelona', 'Chelsea'],
        popularityScore: 91,
        isCellRelevant: true,
      ),
      Player(
        id: 'pedro',
        name: 'Pedro',
        nationalityCode: 'ES',
        primaryPosition: 'Forward',
        clubsPreview: ['Barcelona', 'Chelsea', 'Roma'],
        popularityScore: 76,
        isCellRelevant: true,
      ),
      Player(
        id: 'etoo',
        name: "Samuel Eto'o",
        nationalityCode: 'CM',
        primaryPosition: 'Forward',
        clubsPreview: ['Barcelona', 'Chelsea', 'Inter'],
        popularityScore: 88,
        isCellRelevant: true,
      ),
      Player(
        id: 'ozil',
        name: 'Mesut Özil',
        nationalityCode: 'DE',
        primaryPosition: 'Attacking Midfield',
        clubsPreview: ['Real Madrid', 'Arsenal'],
        popularityScore: 79,
      ),
      Player(
        id: 'modric',
        name: 'Luka Modric',
        nationalityCode: 'HR',
        primaryPosition: 'Midfielder',
        clubsPreview: ['Tottenham', 'Real Madrid'],
        popularityScore: 95,
      ),
      Player(
        id: 'ronaldo',
        name: 'Cristiano Ronaldo',
        nationalityCode: 'PT',
        primaryPosition: 'Forward',
        clubsPreview: ['Man United', 'Real Madrid', 'Juventus'],
        popularityScore: 99,
      ),
      Player(
        id: 'messi',
        name: 'Lionel Messi',
        nationalityCode: 'AR',
        primaryPosition: 'Forward',
        clubsPreview: ['Barcelona', 'PSG', 'Inter Miami'],
        popularityScore: 99,
      ),
    ];

    final suggested = demoPlayers.where((p) => p.isCellRelevant).take(6).toList();

    if (query.isEmpty) {
      return SearchResponse(
        results: demoPlayers.take(limit).toList(),
        suggested: suggested,
        latencyMs: 12,
      );
    }

    final normalized = StringNormalizer.normalize(query);
    final matched = demoPlayers
        .where((p) => StringNormalizer.fuzzyMatch(query, p.name))
        .toList()
      ..sort((a, b) => _demoScore(b, normalized).compareTo(_demoScore(a, normalized)));

    return SearchResponse(
      results: matched.take(limit).toList(),
      suggested: suggested,
      latencyMs: 12,
    );
  }

  int _demoScore(Player player, String normalized) {
    final name = player.name.toLowerCase();
    var score = player.popularityScore;
    if (player.isCellRelevant) score += 120;
    if (name == normalized) {
      score += 1000;
    } else if (name.startsWith(normalized)) {
      score += 500;
    } else if (name.contains(normalized)) {
      score += 200;
    }
    return score;
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
  Future<SearchResponse> search(
    String query, {
    int limit = 20,
    SearchContext? context,
    bool competitive = false,
  }) =>
      _api.search(query, limit: limit, context: context, competitive: competitive);

  @override
  Future<List<Player>> getRecentPicks() async {
    final raw = await _cache.getRecentPicks();
    return raw.map(Player.fromJson).toList();
  }

  @override
  Future<List<Player>> getPopularPicks({int limit = 10, SearchContext? context}) async {
    final response = await _api.search('', limit: limit, context: context);
    return response.results;
  }

  @override
  Future<List<Player>> getSuggestedForCell(SearchContext context, {int limit = 12}) =>
      _api.getSuggested(context, limit: limit);

  @override
  Future<void> recordPick(Player player) async {
    await _cache.addRecentPick(player.toJson());
  }
}
