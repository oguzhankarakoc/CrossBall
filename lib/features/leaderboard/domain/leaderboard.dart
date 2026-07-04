import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.rank,
    required this.userUuid,
    required this.displayName,
    required this.competitiveRating,
    required this.currentLeague,
    required this.currentLevel,
  });

  final int rank;
  final String userUuid;
  final String displayName;
  final double competitiveRating;
  final String currentLeague;
  final int currentLevel;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        userUuid: json['user_uuid'] as String? ?? '',
        displayName: json['display_name'] as String? ?? 'Player',
        competitiveRating: (json['competitive_rating'] as num?)?.toDouble() ?? 0,
        currentLeague: json['current_league'] as String? ?? 'bronze',
        currentLevel: json['current_level'] as int? ?? 1,
      );

  @override
  List<Object?> get props => [rank, userUuid, competitiveRating];
}

abstract interface class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({String? league, int limit = 50});
}
