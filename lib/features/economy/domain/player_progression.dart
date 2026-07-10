import 'package:equatable/equatable.dart';

import 'club_mastery.dart';
import 'player_mission.dart';
import 'season_info.dart';

class PlayerAchievement extends Equatable {
  const PlayerAchievement({
    required this.slug,
    required this.title,
    required this.description,
    required this.unlockedAt,
  });

  final String slug;
  final String title;
  final String description;
  final DateTime unlockedAt;

  factory PlayerAchievement.fromJson(Map<String, dynamic> json) {
    final unlockedRaw = json['unlocked_at'];
    final unlockedAt = unlockedRaw is String
        ? DateTime.tryParse(unlockedRaw)
        : null;
    return PlayerAchievement(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      unlockedAt: unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [slug, unlockedAt];
}

int _jsonInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _jsonDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class PlayerProgression extends Equatable {
  const PlayerProgression({
    this.experiencePoints = 0,
    this.currentLevel = 1,
    this.xpToNextLevel = 0,
    this.competitiveRating = 1000,
    this.currentLeague = 'bronze',
    this.gamesPlayed = 0,
    this.gamesCompleted = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.highestScore = 0,
    this.averageScore = 0,
    this.rareAnswersFound = 0,
    this.legendaryAnswersFound = 0,
    this.perfectGames = 0,
    this.seasonPoints = 0,
    this.achievementPoints = 0,
    this.achievements = const [],
  });

  final int experiencePoints;
  final int currentLevel;
  final int xpToNextLevel;
  final double competitiveRating;
  final String currentLeague;
  final int gamesPlayed;
  final int gamesCompleted;
  final int gamesWon;
  final int currentStreak;
  final int bestStreak;
  final double highestScore;
  final double averageScore;
  final int rareAnswersFound;
  final int legendaryAnswersFound;
  final int perfectGames;
  final int seasonPoints;
  final int achievementPoints;
  final List<PlayerAchievement> achievements;

  factory PlayerProgression.fromJson(Map<String, dynamic> json) {
    final achievementsRaw = json['achievements'] as List<dynamic>? ?? [];
    final achievements = <PlayerAchievement>[];
    for (final entry in achievementsRaw) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        final achievement = PlayerAchievement.fromJson(entry);
        if (achievement.slug.isNotEmpty) achievements.add(achievement);
      } catch (_) {
        // Skip malformed achievement rows from older caches / partial payloads.
      }
    }
    return PlayerProgression(
      experiencePoints: _jsonInt(json['experience_points']),
      currentLevel: _jsonInt(json['current_level'], 1).clamp(1, 9999),
      xpToNextLevel: _jsonInt(json['xp_to_next_level']),
      competitiveRating: _jsonDouble(json['competitive_rating'], 1000),
      currentLeague: json['current_league'] as String? ?? 'bronze',
      gamesPlayed: _jsonInt(json['games_played']),
      gamesCompleted: _jsonInt(json['games_completed']),
      gamesWon: _jsonInt(json['games_won']),
      currentStreak: _jsonInt(json['current_streak']),
      bestStreak: _jsonInt(json['best_streak']),
      highestScore: _jsonDouble(json['highest_score']),
      averageScore: _jsonDouble(json['average_score']),
      rareAnswersFound: _jsonInt(json['rare_answers_found']),
      legendaryAnswersFound: _jsonInt(json['legendary_answers_found']),
      perfectGames: _jsonInt(json['perfect_games']),
      seasonPoints: _jsonInt(json['season_points']),
      achievementPoints: _jsonInt(json['achievement_points']),
      achievements: achievements,
    );
  }

  Map<String, dynamic> toJson() => {
        'experience_points': experiencePoints,
        'current_level': currentLevel,
        'xp_to_next_level': xpToNextLevel,
        'competitive_rating': competitiveRating,
        'current_league': currentLeague,
        'games_played': gamesPlayed,
        'games_completed': gamesCompleted,
        'games_won': gamesWon,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'highest_score': highestScore,
        'average_score': averageScore,
        'rare_answers_found': rareAnswersFound,
        'legendary_answers_found': legendaryAnswersFound,
        'perfect_games': perfectGames,
        'season_points': seasonPoints,
        'achievement_points': achievementPoints,
        'achievements': achievements.map((a) => {
              'slug': a.slug,
              'title': a.title,
              'description': a.description,
              'unlocked_at': a.unlockedAt.toIso8601String(),
            }).toList(),
      };

  @override
  List<Object?> get props => [experiencePoints, currentLevel, competitiveRating];
}

/// Level XP thresholds mirror [economy_level_thresholds] in Supabase.
extension PlayerProgressionLevel on PlayerProgression {
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    final l = level - 1;
    return l * l * 50 + l * 100;
  }

  int get xpForCurrentLevelStart => xpRequiredForLevel(currentLevel);

  int get xpForNextLevelStart => xpRequiredForLevel(currentLevel + 1);

  double get levelProgress {
    final span = xpForNextLevelStart - xpForCurrentLevelStart;
    if (span <= 0) return 1;
    return ((experiencePoints - xpForCurrentLevelStart) / span).clamp(0.0, 1.0);
  }
}

abstract interface class EconomyRepository {
  Future<PlayerProgression> getProgression(String userUuid);
  Future<List<PlayerMission>> getMissions(String userUuid);
  Future<SeasonInfo> getSeason(String userUuid);
  Future<List<ClubMasteryEntry>> getClubMastery(String userUuid, {int limit = 12});
  Future<bool> careerHintTasteAvailable(String userUuid);
}
