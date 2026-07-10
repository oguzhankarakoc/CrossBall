import 'package:equatable/equatable.dart';

import '../../../core/utils/player_display_name.dart';

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

  String get displayLabel => resolvePlayerDisplayLabel(
        displayName: displayName,
        userUuid: userUuid,
      );

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        userUuid: json['user_uuid'] as String? ?? '',
        displayName: json['display_name'] as String? ?? 'Player',
        competitiveRating: (json['competitive_rating'] as num?)?.toDouble() ?? 0,
        currentLeague: json['current_league'] as String? ?? 'bronze',
        currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
      );

  @override
  List<Object?> get props => [rank, userUuid, competitiveRating];
}

class WeeklyDailyScoreDay extends Equatable {
  const WeeklyDailyScoreDay({required this.date, required this.score});

  final String date;
  final double score;

  factory WeeklyDailyScoreDay.fromJson(Map<String, dynamic> json) => WeeklyDailyScoreDay(
        date: json['date'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [date, score];
}

class WeeklyDailyLeaderboardEntry extends Equatable {
  const WeeklyDailyLeaderboardEntry({
    required this.rank,
    required this.userUuid,
    required this.displayName,
    required this.totalScore,
    required this.daysPlayed,
    required this.totalHints,
    required this.totalMistakes,
    required this.dailyScores,
  });

  final int rank;
  final String userUuid;
  final String displayName;
  final double totalScore;
  final int daysPlayed;
  final int totalHints;
  final int totalMistakes;
  final List<WeeklyDailyScoreDay> dailyScores;

  String get displayLabel => resolvePlayerDisplayLabel(
        displayName: displayName,
        userUuid: userUuid,
      );

  factory WeeklyDailyLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      WeeklyDailyLeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        userUuid: json['user_uuid'] as String? ?? '',
        displayName: json['display_name'] as String? ?? 'Player',
        totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
        daysPlayed: json['days_played'] as int? ?? 0,
        totalHints: json['total_hints'] as int? ?? 0,
        totalMistakes: json['total_mistakes'] as int? ?? 0,
        dailyScores: (json['daily_scores'] as List<dynamic>? ?? [])
            .map((e) => WeeklyDailyScoreDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [rank, userUuid, totalScore];
}

class WeeklyDailyLeaderboardSnapshot extends Equatable {
  const WeeklyDailyLeaderboardSnapshot({
    required this.weekKey,
    required this.weekStart,
    required this.weekEnd,
    required this.entries,
    this.myEntry,
  });

  final String weekKey;
  final String weekStart;
  final String weekEnd;
  final List<WeeklyDailyLeaderboardEntry> entries;
  final WeeklyDailyLeaderboardEntry? myEntry;

  factory WeeklyDailyLeaderboardSnapshot.fromJson(Map<String, dynamic> json) =>
      WeeklyDailyLeaderboardSnapshot(
        weekKey: json['week_key'] as String? ?? '',
        weekStart: json['week_start'] as String? ?? '',
        weekEnd: json['week_end'] as String? ?? '',
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => WeeklyDailyLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        myEntry: json['my_entry'] == null
            ? null
            : WeeklyDailyLeaderboardEntry.fromJson(json['my_entry'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [weekKey, entries.length, myEntry?.rank];
}

abstract interface class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({String? league, int limit = 50});

  Future<WeeklyDailyLeaderboardSnapshot?> getWeeklyDailyLeaderboard({
    String? userUuid,
    int limit = 50,
  });
}
