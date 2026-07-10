import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';
import '../domain/challenge.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl({ApiHttpClient? httpClient})
      : _http = httpClient ?? ApiHttpClient();

  final ApiHttpClient _http;

  @override
  Future<Challenge> createChallenge({
    required String puzzleId,
    required String sessionId,
    required double creatorScore,
    required String userUuid,
  }) async {
    try {
      final json = await _http.postJson(
        'challenge-create',
        body: {
          'puzzle_id': puzzleId,
          'session_id': sessionId,
          'creator_score': creatorScore,
          'user_uuid': userUuid,
        },
        headers: ApiConfig.userHeaders(userUuid),
        throwOnError: false,
      );
      if (json.isNotEmpty) return Challenge.fromJson(json);
    } catch (_) {}

    final code = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return Challenge(
      id: code,
      puzzleId: puzzleId,
      shareUrl: 'https://oguzhankarakoc.github.io/CrossBall/challenge.html?c=$code',
      creatorScore: creatorScore,
    );
  }

  @override
  Future<Challenge> getChallenge(String challengeId) async {
    try {
      final json = await _http.getJson(
        'challenge-get',
        query: {'code': challengeId},
        throwOnError: false,
      );
      if (json.isNotEmpty) return Challenge.fromJson(json);
    } catch (_) {}

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
    try {
      final json = await _http.postJson(
        'challenge-complete',
        body: {
          'challenge_id': challengeId,
          'session_id': sessionId,
          'challenger_score': challengerScore,
          'user_uuid': userUuid,
          'mistakes': mistakes,
          'hints_used': hintsUsed,
          'duration_ms': durationMs,
        },
        headers: ApiConfig.userHeaders(userUuid),
        throwOnError: false,
      );
      if (json.isNotEmpty) return ChallengeResult.fromJson(json);
    } catch (_) {}

    return ChallengeResult(
      challengeId: challengeId,
      creatorScore: 0,
      challengerScore: challengerScore,
      youWon: challengerScore > 0,
      isTie: false,
    );
  }
}
