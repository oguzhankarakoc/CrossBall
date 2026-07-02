import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/challenge.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

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
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Content-Type': 'application/json',
            'x-user-uuid': userUuid,
          },
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
    return Challenge(
      id: challengeId,
      puzzleId: '',
      shareUrl: 'crossball://challenge/$challengeId',
    );
  }
}
