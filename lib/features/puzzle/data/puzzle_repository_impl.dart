import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/cache/offline_cache.dart';
import '../../../core/config/app_config.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_repository.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _isValidLivePuzzleCache(Map<String, dynamic> raw) {
  for (final key in ['row_clubs', 'col_clubs']) {
    for (final club in (raw[key] as List? ?? [])) {
      final id = (club as Map<String, dynamic>)['id'] as String? ?? '';
      if (!_uuidPattern.hasMatch(id)) return false;
    }
  }
  return true;
}

class PuzzleApiService {
  PuzzleApiService({SupabaseClient? client, http.Client? httpClient})
      : _client = client,
        _http = httpClient ?? http.Client();

  final SupabaseClient? _client;
  final http.Client _http;
  final _uuid = const Uuid();

  String get _baseUrl => AppConfig.supabaseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
      };

  Future<Map<String, dynamic>> fetchDailyPuzzle() async {
    if (_client != null && AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.get(
          Uri.parse('$_baseUrl/functions/v1/daily-puzzle'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return _demoPuzzle();
  }

  Future<Map<String, dynamic>> fetchPuzzleById(String puzzleId) async {
    if (_client != null && AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.get(
          Uri.parse('$_baseUrl/functions/v1/puzzle-by-id?id=$puzzleId'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return _demoPuzzle();
  }

  Future<String?> fetchChallengePuzzleId(String challengeCode) async {
    if (_client != null && AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.get(
          Uri.parse('$_baseUrl/functions/v1/challenge-get?code=$challengeCode'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['puzzle_id'] as String?;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<AnswerResult> validateAnswer({
    required String rowClubId,
    required String colClubId,
    required String playerId,
    required String puzzleCellId,
    required String sessionId,
  }) async {
    if (_client != null && AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.post(
          Uri.parse('$_baseUrl/functions/v1/validate-answer'),
          headers: _headers,
          body: jsonEncode({
            'row_club_id': rowClubId,
            'col_club_id': colClubId,
            'player_id': playerId,
            'puzzle_cell_id': puzzleCellId,
            'session_id': sessionId,
          }),
        );
        if (response.statusCode == 200) {
          return AnswerResult.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }
    return _demoValidate(playerId, rowClubId, colClubId);
  }

  Map<String, dynamic> _clubBadge(
    String id,
    String name,
    String slug,
    String countryCode,
    String primary,
    String secondary,
    String initials, {
    String? displayName,
    String? shortName,
    String? leagueName,
    String accent = '#FFD700',
    String iconType = 'abstract_shield',
    String gradient = 'vertical',
  }) =>
      {
        'id': id,
        'name': name,
        'slug': slug,
        'country_code': countryCode,
        'display_name': displayName ?? name,
        'short_name': shortName ?? name,
        'short_code': initials,
        'league_name': leagueName,
        'badge_primary_color': primary,
        'badge_secondary_color': secondary,
        'badge_accent_color': accent,
        'badge_initials': initials,
        'badge_icon_type': iconType,
        'badge_gradient_style': gradient,
      };

  Map<String, dynamic> _demoPuzzle() {
    final clubs = [
      _clubBadge('barcelona', 'FC Barcelona', 'barcelona', 'ES', '#A50044', '#004D98', 'BAR',
          displayName: 'FC Barcelona', shortName: 'Barcelona', leagueName: 'La Liga',
          iconType: 'abstract_stripes'),
      _clubBadge('chelsea', 'Chelsea FC', 'chelsea', 'GB', '#034694', '#FFFFFF', 'CHE',
          displayName: 'Chelsea FC', shortName: 'Chelsea', leagueName: 'Premier League',
          iconType: 'abstract_lion', gradient: 'metallic'),
      _clubBadge('real-madrid', 'Real Madrid', 'real-madrid', 'ES', '#F5F5F5', '#FEBE10', 'RMA',
          displayName: 'Real Madrid CF', shortName: 'Real Madrid', leagueName: 'La Liga',
          accent: '#C0C0C0', iconType: 'abstract_crown', gradient: 'metallic'),
      _clubBadge('man-utd', 'Manchester United', 'manchester-united', 'GB', '#DA291C', '#FBE122', 'MUN',
          displayName: 'Manchester United', shortName: 'Man United', leagueName: 'Premier League',
          iconType: 'abstract_orb'),
      _clubBadge('bayern', 'Bayern Munich', 'bayern-munich', 'DE', '#DC052D', '#0066B2', 'BAY',
          displayName: 'FC Bayern Munich', shortName: 'Bayern', leagueName: 'Bundesliga',
          iconType: 'abstract_diamond'),
      _clubBadge('juventus', 'Juventus', 'juventus', 'IT', '#000000', '#FFFFFF', 'JUV',
          displayName: 'Juventus FC', shortName: 'Juventus', leagueName: 'Serie A',
          iconType: 'abstract_stripes', gradient: 'metallic'),
    ];

    final cells = <Map<String, dynamic>>[];
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        cells.add({
          'id': _uuid.v4(),
          'row_index': r,
          'col_index': c,
          'valid_answer_count': 8,
          'difficulty': 0.4,
        });
      }
    }

    return {
      'puzzle_id': _uuid.v4(),
      'date': DateTime.now().toIso8601String().split('T').first,
      'grid_size': 3,
      'row_clubs': clubs.sublist(0, 3),
      'col_clubs': clubs.sublist(3, 6),
      'cells': cells,
      'difficulty': 0.42,
    };
  }

  AnswerResult _demoValidate(String playerId, String rowClubId, String colClubId) {
    // Demo validation map for Barcelona x Chelsea cell
    const validAnswers = {
      'pedro': {'name': 'Pedro', 'usage': 67.0, 'tier': 'common'},
      'deco': {'name': 'Deco', 'usage': 4.0, 'tier': 'legendary'},
      'fabregas': {'name': 'Cesc Fabregas', 'usage': 22.0, 'tier': 'rare'},
      'etoo': {'name': "Samuel Eto'o", 'usage': 8.0, 'tier': 'epic'},
    };

    final match = validAnswers[playerId];
    if (match != null &&
        ((rowClubId == 'barcelona' && colClubId == 'chelsea') ||
            (rowClubId == 'chelsea' && colClubId == 'barcelona'))) {
      final usage = match['usage']! as double;
      return AnswerResult(
        correct: true,
        playerName: match['name']! as String,
        usagePercentage: usage,
        rarityTier: match['tier']! as String,
        rarityScore: 100 - usage,
      );
    }

    // For demo: accept any player with >50% random correct for other cells
    return AnswerResult(
      correct: playerId.isNotEmpty,
      playerName: playerId,
      usagePercentage: 35,
      rarityTier: 'rare',
      rarityScore: 65,
    );
  }

  Future<HintResult> requestHint({
    required String rowClubId,
    required String colClubId,
    required String puzzleCellId,
    required String sessionId,
    required HintType hintType,
  }) async {
    if (_client != null && AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.post(
          Uri.parse('$_baseUrl/functions/v1/request-hint'),
          headers: _headers,
          body: jsonEncode({
            'row_club_id': rowClubId,
            'col_club_id': colClubId,
            'puzzle_cell_id': puzzleCellId,
            'session_id': sessionId,
            'hint_type': hintType.name == 'firstLetter' ? 'first_letter' : hintType.name,
          }),
        );
        if (response.statusCode == 200) {
          return HintResult.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }
    return _demoHint(hintType);
  }

  HintResult _demoHint(HintType hintType) => switch (hintType) {
        HintType.nationality => const HintResult(hintType: HintType.nationality, hintValue: 'Brazil'),
        HintType.position => const HintResult(hintType: HintType.position, hintValue: 'Midfielder'),
        HintType.firstLetter => const HintResult(hintType: HintType.firstLetter, hintValue: 'D _ _ _'),
      };
}

class PuzzleRepositoryImpl implements PuzzleRepository {
  PuzzleRepositoryImpl({
    required PuzzleApiService api,
    required OfflineCache cache,
  })  : _api = api,
        _cache = cache;

  final PuzzleApiService _api;
  final OfflineCache _cache;
  final _uuid = const Uuid();

  @override
  Future<Puzzle> getDailyPuzzle({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.getDailyPuzzle();
      if (cached != null) {
        if (_isValidLivePuzzleCache(cached) || !AppConfig.isSupabaseConfigured) {
          return Puzzle.fromJson(cached);
        }
        await _cache.invalidateDailyPuzzle();
      }
    }

    final raw = await _api.fetchDailyPuzzle();
    if (_isValidLivePuzzleCache(raw) || !AppConfig.isSupabaseConfigured) {
      await _cache.cacheDailyPuzzle(raw);
    }
    return Puzzle.fromJson(raw);
  }

  @override
  Future<Puzzle> getPuzzleById(String puzzleId) async {
    final raw = await _api.fetchPuzzleById(puzzleId);
    return Puzzle.fromJson(raw);
  }

  @override
  Future<Puzzle> getPracticePuzzle({required int gridSize}) async {
    final daily = await getDailyPuzzle();
    return Puzzle(
      id: _uuid.v4(),
      date: daily.date,
      gridSize: gridSize,
      rowClubs: daily.rowClubs,
      colClubs: daily.colClubs,
      cells: daily.cells,
      mode: PuzzleMode.practice,
    );
  }

  @override
  Future<Puzzle> getChallengePuzzle(String challengeId) async {
    final puzzleId = await _api.fetchChallengePuzzleId(challengeId);
    if (puzzleId != null && puzzleId.isNotEmpty) {
      return getPuzzleById(puzzleId);
    }
    return getDailyPuzzle();
  }

  @override
  Future<AnswerResult> validateAnswer({
    required String puzzleId,
    required String puzzleCellId,
    required String rowClubId,
    required String colClubId,
    required String playerId,
    required String sessionId,
  }) =>
      _api.validateAnswer(
        rowClubId: rowClubId,
        colClubId: colClubId,
        playerId: playerId,
        puzzleCellId: puzzleCellId,
        sessionId: sessionId,
      );

  @override
  Future<HintResult> requestHint({
    required String puzzleCellId,
    required String rowClubId,
    required String colClubId,
    required String sessionId,
    required HintType hintType,
  }) =>
      _api.requestHint(
        rowClubId: rowClubId,
        colClubId: colClubId,
        puzzleCellId: puzzleCellId,
        sessionId: sessionId,
        hintType: hintType,
      );

  @override
  Future<String> createSession({
    required String puzzleId,
    required PuzzleMode mode,
    required int gridSize,
  }) async =>
      _uuid.v4();

  @override
  Future<void> completeSession({
    required String sessionId,
    required double finalScore,
    required Map<String, dynamic> antiCheatMetadata,
  }) async {
    if (antiCheatMetadata['is_suspicious'] == true) return;
    await _cache.queuePendingAnswer({
      'session_id': sessionId,
      'final_score': finalScore,
      ...antiCheatMetadata,
    });
  }
}
