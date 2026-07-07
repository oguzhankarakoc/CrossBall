import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/cache/offline_cache.dart';
import '../../../core/config/app_config.dart';
import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/utils/daily_puzzle_schedule.dart';
import '../../../core/debug/practice_debug_log.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_fetch_exception.dart';
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

String _extractApiErrorField(Object? errorField) {
  if (errorField == null) return '';
  if (errorField is String) return errorField;
  if (errorField is Map) {
    for (final key in ['message', 'details', 'hint', 'code', 'error']) {
      final value = errorField[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return jsonEncode(errorField);
  }
  return errorField.toString();
}

PuzzleFetchException _dailyFetchExceptionFromResponse(int statusCode, String body) {
  String detail = '';
  String? errorCode;
  int? retryAfter;
  DateTime? startedAt;
  try {
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    detail = _extractApiErrorField(parsed['error']);
    errorCode = parsed['code'] as String?;
    retryAfter = (parsed['retry_after'] as num?)?.toInt();
    final startedRaw = parsed['started_at'];
    if (startedRaw is String && startedRaw.isNotEmpty) {
      startedAt = DateTime.tryParse(startedRaw);
    }
  } catch (_) {
    detail = body.length > 180 ? '${body.substring(0, 180)}…' : body;
  }

  return PuzzleFetchException(
    detail.isNotEmpty
        ? 'Daily puzzle unavailable: $detail'
        : 'Daily puzzle unavailable ($statusCode)',
    statusCode: statusCode,
    errorCode: errorCode,
    retryAfterSeconds: retryAfter,
    rolloutStartedAt: startedAt,
  );
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

  Future<Map<String, dynamic>> fetchDailyPuzzle({String? userUuid}) async {
    cbDebug('Daily', 'fetchDailyPuzzle start', {
      'userUuid': userUuid,
      'supabaseConfigured': AppConfig.isSupabaseConfigured,
      'hasClient': _client != null,
      'baseHost': Uri.tryParse(_baseUrl)?.host ?? _baseUrl,
    });

    if (_client != null && AppConfig.isSupabaseConfigured) {
      final stopwatch = Stopwatch()..start();
      try {
        final query = userUuid != null ? '?user_uuid=$userUuid' : '';
        final uri = Uri.parse('$_baseUrl/functions/v1/daily-puzzle$query');
        cbDebug('Daily', 'HTTP GET', uri.toString());

        final response = await _http
            .get(uri, headers: _headers)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw const PuzzleFetchException('Daily puzzle request timed out after 30s');
              },
            );
        stopwatch.stop();
        cbDebugHttpResponse(
          'Daily',
          'daily-puzzle response',
          uri: uri.toString(),
          statusCode: response.statusCode,
          elapsedMs: stopwatch.elapsedMilliseconds,
          body: response.body,
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          cbDebug('Daily', 'fetchDailyPuzzle OK', {
            'puzzle_id': decoded['puzzle_id'] ?? decoded['id'],
            'date': decoded['date'],
            'row_clubs': (decoded['row_clubs'] as List?)?.length,
            'col_clubs': (decoded['col_clubs'] as List?)?.length,
          });
          return decoded;
        }

        throw _dailyFetchExceptionFromResponse(response.statusCode, response.body);
      } on PuzzleFetchException catch (e, st) {
        cbDebugError('Daily', 'PuzzleFetchException', e, st);
        rethrow;
      } catch (e, st) {
        stopwatch.stop();
        cbDebugError(
          'Daily',
          'network/parse error after ${stopwatch.elapsedMilliseconds}ms',
          e,
          st,
        );
        throw PuzzleFetchException('Daily puzzle network error: $e');
      }
    }

    cbDebug('Daily', 'using demo puzzle (Supabase not configured or no client)');
    return _demoPuzzle();
  }

  Future<Map<String, dynamic>> fetchDailyRolloutStatus() async {
    if (_client == null || !AppConfig.isSupabaseConfigured) {
      return {
        'puzzle_date': DailyPuzzleSchedule.todayPuzzleDateUtc(),
        'status': 'ready',
        'retry_after': 0,
      };
    }

    final uri = Uri.parse('$_baseUrl/functions/v1/daily-puzzle?status_only=true');
    cbDebug('Daily', 'HTTP GET rollout status', uri.toString());

    final stopwatch = Stopwatch()..start();
    final response = await _http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    stopwatch.stop();

    cbDebugHttpResponse(
      'Daily',
      'daily-puzzle status',
      uri: uri.toString(),
      statusCode: response.statusCode,
      elapsedMs: stopwatch.elapsedMilliseconds,
      body: response.body,
    );

    if (response.statusCode == 200 || response.statusCode == 503) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _dailyFetchExceptionFromResponse(response.statusCode, response.body);
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
    required String userUuid,
    int? responseTimeMs,
  }) async {
    if (_client != null && AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.post(
          Uri.parse('$_baseUrl/functions/v1/validate-answer'),
          headers: {
            ..._headers,
            'x-user-uuid': userUuid,
          },
          body: jsonEncode({
            'row_club_id': rowClubId,
            'col_club_id': colClubId,
            'player_id': playerId,
            'puzzle_cell_id': puzzleCellId,
            'session_id': sessionId,
            'response_time_ms': ?responseTimeMs,
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

  Future<SessionStartResult> startSession({
    required String userUuid,
    required String puzzleId,
    required String mode,
    required int gridSize,
  }) async {
    cbDebug('Session', 'startSession request', {
      'mode': mode,
      'puzzleId': puzzleId,
      'gridSize': gridSize,
      'userUuid': userUuid,
    });

    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse('$_baseUrl/functions/v1/start-session');
    try {
      final response = await _http
          .post(
            uri,
            headers: {
              ..._headers,
              'x-user-uuid': userUuid,
            },
            body: jsonEncode({
              'user_uuid': userUuid,
              'puzzle_id': puzzleId,
              'mode': mode,
              'grid_size': gridSize,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw const PuzzleFetchException('start-session timed out after 20s');
            },
          );
      stopwatch.stop();
      cbDebugHttpResponse(
        'Session',
        'start-session response',
        uri: uri.toString(),
        statusCode: response.statusCode,
        elapsedMs: stopwatch.elapsedMilliseconds,
        body: response.body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sessionId = data['session_id'] as String?;
        final startedAtRaw = data['started_at'] as String?;
        if (sessionId != null &&
            sessionId.isNotEmpty &&
            startedAtRaw != null &&
            startedAtRaw.isNotEmpty) {
          final result = SessionStartResult.fromJson(data);
          cbDebug('Session', 'startSession OK', {
            'sessionId': sessionId,
            'resumed': result.resumed,
            'answers': result.answers.length,
            'hints': result.hints.length,
          });
          return result;
        }
        cbDebug('Session', 'startSession missing session_id/started_at in 200 body');
      }

      String detail = '';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        detail = body['error']?.toString() ?? '';
      } catch (_) {}

      throw PuzzleFetchException(
        detail.isNotEmpty
            ? 'Failed to start session: $detail'
            : 'Failed to start session (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on PuzzleFetchException catch (e, st) {
      cbDebugError('Session', 'startSession failed', e, st);
      rethrow;
    } catch (e, st) {
      cbDebugError('Session', 'startSession network error', e, st);
      throw PuzzleFetchException('start-session network error: $e');
    }
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

  Future<Map<String, dynamic>> fetchPracticePuzzle({
    required int gridSize,
    required String userUuid,
    String? excludePuzzleId,
  }) async {
    practiceDebug('fetchPracticePuzzle start', {
      'gridSize': gridSize,
      'userUuid': userUuid,
      'excludePuzzleId': excludePuzzleId,
      'supabaseConfigured': AppConfig.isSupabaseConfigured,
      'hasClient': _client != null,
    });

    if (_client != null && AppConfig.isSupabaseConfigured) {
      final stopwatch = Stopwatch()..start();
      try {
        final excludeQuery = excludePuzzleId != null && excludePuzzleId.isNotEmpty
            ? '&exclude_puzzle_id=$excludePuzzleId'
            : '';
        final uri = Uri.parse(
          '$_baseUrl/functions/v1/practice-puzzle?grid_size=$gridSize&user_uuid=$userUuid$excludeQuery',
        );
        practiceDebug('HTTP GET', uri.toString());

        final response = await _http
            .get(
              uri,
              headers: {
                ..._headers,
                'x-user-uuid': userUuid,
              },
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw PuzzleFetchException(
                  'Practice puzzle request timed out after 60s',
                );
              },
            );
        stopwatch.stop();
        practiceDebug('HTTP response', {
          'status': response.statusCode,
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'bodyPreview': response.body.length > 400
              ? '${response.body.substring(0, 400)}…'
              : response.body,
        });

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          practiceDebug('fetchPracticePuzzle OK', {
            'puzzle_id': decoded['puzzle_id'] ?? decoded['id'],
            'row_clubs': (decoded['row_clubs'] as List?)?.length,
            'col_clubs': (decoded['col_clubs'] as List?)?.length,
          });
          return decoded;
        }
        String detail = '';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          detail = body['error']?.toString() ?? '';
        } catch (parseErr) {
          practiceDebug('error body parse failed', parseErr);
        }
        practiceDebug('HTTP non-200', {'detail': detail, 'status': response.statusCode});
        throw PuzzleFetchException(
          detail.isNotEmpty
              ? 'Practice puzzle unavailable: $detail'
              : 'Practice puzzle unavailable (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } on PuzzleFetchException catch (e, st) {
        practiceDebugError('PuzzleFetchException', e, st);
        rethrow;
      } catch (e, st) {
        stopwatch.stop();
        practiceDebugError(
          'network/parse error after ${stopwatch.elapsedMilliseconds}ms',
          e,
          st,
        );
        throw PuzzleFetchException('Practice puzzle network error: $e');
      }
    }

    practiceDebug('using demo puzzle (Supabase not configured or no client)');
    return _demoPuzzle();
  }

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
      _clubBadge('bayern-munich', 'Bayern Munich', 'bayern-munich', 'DE', '#DC052D', '#0066B2', 'BAY',
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
    const validAnswers = {
      'pedro': {'name': 'Pedro', 'usage': 67.0, 'tier': 'common'},
      'deco': {'name': 'Deco', 'usage': 4.0, 'tier': 'legendary'},
      'fabregas': {'name': 'Cesc Fabregas', 'usage': 22.0, 'tier': 'rare'},
      'etoo': {'name': "Samuel Eto'o", 'usage': 8.0, 'tier': 'epic'},
    };

    bool matchesClub(String ref, String slug) =>
        ref == slug || ref.replaceAll('-', '') == slug.replaceAll('-', '');

    final isBarcelonaChelsea =
        (matchesClub(rowClubId, 'barcelona') && matchesClub(colClubId, 'chelsea')) ||
        (matchesClub(rowClubId, 'chelsea') && matchesClub(colClubId, 'barcelona'));

    final match = validAnswers[playerId];
    if (match != null && isBarcelonaChelsea) {
      final usage = match['usage']! as double;
      return AnswerResult(
        correct: true,
        playerName: match['name']! as String,
        usagePercentage: usage,
        rarityTier: match['tier']! as String,
        rarityScore: 100 - usage,
      );
    }

    // Offline demo: reject unknown players instead of accepting everything.
    return AnswerResult(
      correct: false,
      playerName: playerId,
      usagePercentage: 0,
      rarityTier: 'common',
      rarityScore: 0,
    );
  }

  Future<HintResult> requestHint({
    required String rowClubId,
    required String colClubId,
    required String puzzleCellId,
    required String sessionId,
    required HintType hintType,
    String? userUuid,
    String? adToken,
  }) async {
    if (_client != null && AppConfig.isSupabaseConfigured) {
      try {
        final headers = {
          ..._headers,
          'x-user-uuid': ?userUuid,
        };
        final response = await _http.post(
          Uri.parse('$_baseUrl/functions/v1/request-hint'),
          headers: headers,
          body: jsonEncode({
            'row_club_id': rowClubId,
            'col_club_id': colClubId,
            'puzzle_cell_id': puzzleCellId,
            'session_id': sessionId,
            'hint_type': _hintTypeToApi(hintType),
            'ad_token': ?adToken,
            'user_uuid': ?userUuid,
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

  Future<bool> grantHintAdToken({
    required String userUuid,
    required String adToken,
    required String sessionId,
  }) async {
    if (_client == null || !AppConfig.isSupabaseConfigured) return false;

    try {
      final response = await _http.post(
        Uri.parse('$_baseUrl/functions/v1/grant-hint-ad'),
        headers: {
          ..._headers,
          'x-user-uuid': userUuid,
        },
        body: jsonEncode({
          'ad_token': adToken,
          'user_uuid': userUuid,
          'session_id': sessionId,
        }),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['ok'] == true;
      }
    } catch (_) {}
    return false;
  }

  String _hintTypeToApi(HintType hintType) => switch (hintType) {
        HintType.nationality => 'nationality',
        HintType.position => 'position',
        HintType.firstLetter => 'first_letter',
        HintType.careerLeague => 'career_league',
        HintType.retiredStatus => 'retired_status',
        HintType.careerClub => 'career_club',
      };

  HintResult _demoHint(HintType hintType) => switch (hintType) {
        HintType.nationality => const HintResult(hintType: HintType.nationality, hintValue: 'Brazil'),
        HintType.position => const HintResult(hintType: HintType.position, hintValue: 'Midfielder'),
        HintType.firstLetter => const HintResult(hintType: HintType.firstLetter, hintValue: 'D _ _ _'),
        HintType.careerLeague => const HintResult(hintType: HintType.careerLeague, hintValue: 'Premier League'),
        HintType.retiredStatus => const HintResult(hintType: HintType.retiredStatus, hintValue: 'Active'),
        HintType.careerClub => const HintResult(hintType: HintType.careerClub, hintValue: 'Arsenal'),
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
  Future<Puzzle> getDailyPuzzle({bool forceRefresh = false, String? userUuid}) async {
    final today = DailyPuzzleSchedule.todayPuzzleDateUtc();
    cbDebug('Daily', 'getDailyPuzzle', {'today': today, 'forceRefresh': forceRefresh});

    if (!forceRefresh) {
      final cached = await _cache.getDailyPuzzle(forDate: today);
      if (cached != null) {
        final cachedDate = cached['date'] as String? ?? cached['puzzle_date'] as String?;
        if (cachedDate != null && cachedDate != today) {
          cbDebug('Daily', 'stale cache for previous day — invalidating', {
            'cachedDate': cachedDate,
            'today': today,
          });
          await _cache.invalidateDailyPuzzle();
        } else {
          final valid = _isValidLivePuzzleCache(cached) || !AppConfig.isSupabaseConfigured;
          cbDebug('Daily', 'cache lookup', {
            'hit': true,
            'valid': valid,
            'puzzle_id': cached['puzzle_id'] ?? cached['id'],
          });
          if (valid) {
            return Puzzle.fromJson(cached);
          }
          cbDebug('Daily', 'invalid cache — invalidating (non-UUID club ids?)');
          await _cache.invalidateDailyPuzzle();
        }
      } else {
        cbDebug('Daily', 'cache lookup', {'hit': false});
      }
    }

    try {
      final raw = await _api.fetchDailyPuzzle(userUuid: userUuid);
      if (!_isValidLivePuzzleCache(raw) && AppConfig.isSupabaseConfigured) {
        cbDebug('Daily', 'invalid live payload — club ids must be UUIDs', {
          'row_sample': (raw['row_clubs'] as List?)?.first,
          'col_sample': (raw['col_clubs'] as List?)?.first,
        });
        throw const PuzzleFetchException('Invalid daily puzzle payload');
      }
      if (_isValidLivePuzzleCache(raw) || !AppConfig.isSupabaseConfigured) {
        await _cache.cacheDailyPuzzle(raw);
        cbDebug('Daily', 'cached fresh daily puzzle');
      }
      return Puzzle.fromJson(raw);
    } on PuzzleFetchException catch (e) {
      cbDebugError('Daily', 'getDailyPuzzle fetch failed', e);
      if (e.isGenerationInProgress || e.isGenerationFailed) {
        rethrow;
      }
      cbDebug('Daily', 'no valid cache fallback for daily (previous day closed at UTC midnight)');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchDailyRolloutStatus() => _api.fetchDailyRolloutStatus();

  @override
  Future<Puzzle> getPuzzleById(String puzzleId) async {
    final raw = await _api.fetchPuzzleById(puzzleId);
    return Puzzle.fromJson(raw);
  }

  @override
  Future<Puzzle> getPracticePuzzle({
    required int gridSize,
    required String userUuid,
    String? excludePuzzleId,
  }) async {
    final raw = await _api.fetchPracticePuzzle(
      gridSize: gridSize,
      userUuid: userUuid,
      excludePuzzleId: excludePuzzleId,
    );
    try {
      return _practiceFromRaw(raw);
    } catch (e, st) {
      practiceDebugError('Puzzle.fromJson failed for practice payload', e, st);
      practiceDebug('raw keys', raw.keys.toList());
      rethrow;
    }
  }

  Puzzle _practiceFromRaw(Map<String, dynamic> raw) {
    final puzzle = Puzzle.fromJson(raw);
    return Puzzle(
      id: puzzle.id,
      date: puzzle.date,
      gridSize: puzzle.gridSize,
      rowClubs: puzzle.rowClubs,
      colClubs: puzzle.colClubs,
      cells: puzzle.cells,
      mode: PuzzleMode.practice,
      difficulty: puzzle.difficulty,
      difficultyTier: puzzle.difficultyTier,
      qualityScore: puzzle.qualityScore,
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
    required String userUuid,
    int? responseTimeMs,
  }) =>
      _api.validateAnswer(
        rowClubId: rowClubId,
        colClubId: colClubId,
        playerId: playerId,
        puzzleCellId: puzzleCellId,
        sessionId: sessionId,
        userUuid: userUuid,
        responseTimeMs: responseTimeMs,
      );

  @override
  Future<HintResult> requestHint({
    required String puzzleCellId,
    required String rowClubId,
    required String colClubId,
    required String sessionId,
    required HintType hintType,
    String? userUuid,
    String? adToken,
  }) =>
      _api.requestHint(
        rowClubId: rowClubId,
        colClubId: colClubId,
        puzzleCellId: puzzleCellId,
        sessionId: sessionId,
        hintType: hintType,
        userUuid: userUuid,
        adToken: adToken,
      );

  @override
  Future<bool> grantHintAdToken({
    required String userUuid,
    required String adToken,
    required String sessionId,
  }) =>
      _api.grantHintAdToken(
        userUuid: userUuid,
        adToken: adToken,
        sessionId: sessionId,
      );

  @override
  Future<SessionStartResult> createSession({
    required String puzzleId,
    required PuzzleMode mode,
    required int gridSize,
    String? userUuid,
  }) async {
    if (AppConfig.isSupabaseConfigured && userUuid != null) {
      return _api.startSession(
        userUuid: userUuid,
        puzzleId: puzzleId,
        mode: mode.name,
        gridSize: gridSize,
      );
    }
    final localId = _uuid.v4();
    cbDebug('Session', 'using local session UUID (offline/demo)', {
      'sessionId': localId,
      'mode': mode.name,
      'supabaseConfigured': AppConfig.isSupabaseConfigured,
      'hasUserUuid': userUuid != null,
    });
    return SessionStartResult(
      sessionId: localId,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<void> completeSession({
    required String sessionId,
    required double finalScore,
    required Map<String, dynamic> antiCheatMetadata,
  }) async {
    await _cache.queuePendingAnswer({
      'session_id': sessionId,
      ...antiCheatMetadata,
    });
  }
}
