import 'package:equatable/equatable.dart';

class DailyScoreEntry extends Equatable {
  const DailyScoreEntry({
    required this.date,
    required this.score,
  });

  final String date;
  final double score;

  factory DailyScoreEntry.fromJson(Map<String, dynamic> json) => DailyScoreEntry(
        date: json['date'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [date, score];
}

class UserStats extends Equatable {
  const UserStats({
    this.gamesPlayed = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalScore = 0,
    this.rarityBreakdown = const {},
    this.weeklyDailyScores = const [],
    this.dailyCompletedToday = false,
    this.todayDailyScore = 0,
  });

  final int gamesPlayed;
  final int currentStreak;
  final int bestStreak;
  final double totalScore;
  final Map<String, int> rarityBreakdown;
  final List<DailyScoreEntry> weeklyDailyScores;
  final bool dailyCompletedToday;
  final double todayDailyScore;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        gamesPlayed: json['games_played'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
        bestStreak: json['best_streak'] as int? ?? 0,
        totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
        rarityBreakdown:
            (json['rarity_breakdown'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, v as int)),
        weeklyDailyScores: (json['weekly_daily_scores'] as List<dynamic>? ?? [])
            .map((e) => DailyScoreEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyCompletedToday: json['daily_completed_today'] as bool? ?? false,
        todayDailyScore: (json['today_daily_score'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'games_played': gamesPlayed,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'total_score': totalScore,
        'rarity_breakdown': rarityBreakdown,
        'weekly_daily_scores':
            weeklyDailyScores.map((e) => {'date': e.date, 'score': e.score}).toList(),
        'daily_completed_today': dailyCompletedToday,
        'today_daily_score': todayDailyScore,
      };

  @override
  List<Object?> get props =>
      [gamesPlayed, currentStreak, totalScore, weeklyDailyScores, dailyCompletedToday];
}

abstract interface class StatsRepository {
  Future<UserStats> getStats(String userUuid);
}
