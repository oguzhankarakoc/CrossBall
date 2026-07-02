import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  const UserStats({
    this.gamesPlayed = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalScore = 0,
    this.rarityBreakdown = const {},
  });

  final int gamesPlayed;
  final int currentStreak;
  final int bestStreak;
  final double totalScore;
  final Map<String, int> rarityBreakdown;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        gamesPlayed: json['games_played'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
        bestStreak: json['best_streak'] as int? ?? 0,
        totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
        rarityBreakdown:
            (json['rarity_breakdown'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, v as int)),
      );

  Map<String, dynamic> toJson() => {
        'games_played': gamesPlayed,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'total_score': totalScore,
        'rarity_breakdown': rarityBreakdown,
      };

  @override
  List<Object?> get props => [gamesPlayed, currentStreak, totalScore];
}

abstract interface class StatsRepository {
  Future<UserStats> getStats(String userUuid);
}
