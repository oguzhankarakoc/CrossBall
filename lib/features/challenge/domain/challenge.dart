import 'package:equatable/equatable.dart';

class Challenge extends Equatable {
  const Challenge({
    required this.id,
    required this.puzzleId,
    required this.shareUrl,
    this.creatorScore = 0,
    this.challengerScore,
    this.status = 'open',
  });

  final String id;
  final String puzzleId;
  final String shareUrl;
  final double creatorScore;
  final double? challengerScore;
  final String status;

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['challenge_id'] as String,
        puzzleId: json['puzzle_id'] as String? ?? '',
        shareUrl: json['share_url'] as String? ?? '',
        creatorScore: (json['creator_score'] as num?)?.toDouble() ?? 0,
        challengerScore: (json['challenger_score'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'open',
      );

  @override
  List<Object?> get props => [id, puzzleId];
}

abstract interface class ChallengeRepository {
  Future<Challenge> createChallenge({
    required String puzzleId,
    required String sessionId,
    required double creatorScore,
    required String userUuid,
  });
  Future<Challenge> getChallenge(String challengeId);
}
