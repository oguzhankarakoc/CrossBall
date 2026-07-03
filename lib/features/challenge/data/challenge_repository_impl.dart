import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/challenge.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Map<String, String> get _headers => {
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
      };

  @override
  Future<Challenge> createChallenge({
    required String puzzleId,
    required String sessionId,
    required double creatorScore,
    required String userUuid,
  }) async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.post(
          Uri.parse('${AppConfig.supabaseUrl}/functions/v1/challenge-create'),
          headers: {..._headers, 'x-user-uuid': userUuid},
          body: jsonEncode({
            'puzzle_id': puzzleId,
            'session_id': sessionId,
            'creator_score': creatorScore,
            'user_uuid': userUuid,
          }),
        );
        if (response.statusCode == 200) {
          return Challenge.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }

    final code = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return Challenge(
      id: code,
      puzzleId: puzzleId,
      shareUrl: 'crossball://challenge/$code',
      creatorScore: creatorScore,
    );
  }

  @override
  Future<Challenge> getChallenge(String challengeId) async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.get(
          Uri.parse(
            '${AppConfig.supabaseUrl}/functions/v1/challenge-get?code=$challengeId',
          ),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          return Challenge.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }

    return Challenge(
      id: challengeId,
      puzzleId: '',
      shareUrl: 'crossball://challenge/$challengeId',
    );
  }

  @override
  Future<ChallengeResult> completeChallenge({
    required String challengeId,
    required String sessionId,
    required double challengerScore,
    required String userUuid,
    required int mistakes,
    required int hintsUsed,
    required int durationMs,
  }) async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        final response = await _http.post(
          Uri.parse('${AppConfig.supabaseUrl}/functions/v1/challenge-complete'),
          headers: {..._headers, 'x-user-uuid': userUuid},
          body: jsonEncode({
            'challenge_id': challengeId,
            'session_id': sessionId,
            'challenger_score': challengerScore,
            'user_uuid': userUuid,
            'mistakes': mistakes,
            'hints_used': hintsUsed,
            'duration_ms': durationMs,
          }),
        );
        if (response.statusCode == 200) {
          return ChallengeResult.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }

    return ChallengeResult(
      challengeId: challengeId,
      creatorScore: 0,
      challengerScore: challengerScore,
      youWon: challengerScore > 0,
      isTie: false,
    );
  }
}
