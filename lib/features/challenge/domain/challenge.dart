import 'package:equatable/equatable.dart';

class Challenge extends Equatable {
  const Challenge({
    required this.id,
    required this.puzzleId,
    required this.shareUrl,
    this.creatorScore = 0,
    this.challengerScore,
    this.status = 'open',
    this.youWon,
    this.isTie = false,
  });

  final String id;
  final String puzzleId;
  final String shareUrl;
  final double creatorScore;
  final double? challengerScore;
  final String status;
  final bool? youWon;
  final bool isTie;

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['challenge_id'] as String,
        puzzleId: json['puzzle_id'] as String? ?? '',
        shareUrl: json['share_url'] as String? ?? '',
        creatorScore: (json['creator_score'] as num?)?.toDouble() ?? 0,
        challengerScore: (json['challenger_score'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'open',
        youWon: json['you_won'] as bool?,
        isTie: json['is_tie'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, puzzleId, status];
}

class ChallengeResult extends Equatable {
  const ChallengeResult({
    required this.challengeId,
    required this.creatorScore,
    required this.challengerScore,
    required this.youWon,
    required this.isTie,
  });

  final String challengeId;
  final double creatorScore;
  final double challengerScore;
  final bool youWon;
  final bool isTie;

  factory ChallengeResult.fromJson(Map<String, dynamic> json) => ChallengeResult(
        challengeId: json['challenge_id'] as String,
        creatorScore: (json['creator_score'] as num?)?.toDouble() ?? 0,
        challengerScore: (json['challenger_score'] as num?)?.toDouble() ?? 0,
        youWon: json['you_won'] as bool? ?? false,
        isTie: json['is_tie'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [challengeId, youWon];
}

abstract interface class ChallengeRepository {
  Future<Challenge> createChallenge({
    required String puzzleId,
    required String sessionId,
    required double creatorScore,
    required String userUuid,
  });
  Future<Challenge> getChallenge(String challengeId);
  Future<ChallengeResult> completeChallenge({
    required String challengeId,
    required String sessionId,
    required double challengerScore,
    required String userUuid,
    required int mistakes,
    required int hintsUsed,
    required int durationMs,
  });
}
