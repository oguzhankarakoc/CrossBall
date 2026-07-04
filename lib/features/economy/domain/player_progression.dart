import 'package:equatable/equatable.dart';

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

  factory PlayerAchievement.fromJson(Map<String, dynamic> json) => PlayerAchievement(
        slug: json['slug'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      );

  @override
  List<Object?> get props => [slug, unlockedAt];
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
    return PlayerProgression(
      experiencePoints: json['experience_points'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      xpToNextLevel: json['xp_to_next_level'] as int? ?? 0,
      competitiveRating: (json['competitive_rating'] as num?)?.toDouble() ?? 1000,
      currentLeague: json['current_league'] as String? ?? 'bronze',
      gamesPlayed: json['games_played'] as int? ?? 0,
      gamesCompleted: json['games_completed'] as int? ?? 0,
      gamesWon: json['games_won'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      highestScore: (json['highest_score'] as num?)?.toDouble() ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
      rareAnswersFound: json['rare_answers_found'] as int? ?? 0,
      legendaryAnswersFound: json['legendary_answers_found'] as int? ?? 0,
      perfectGames: json['perfect_games'] as int? ?? 0,
      seasonPoints: json['season_points'] as int? ?? 0,
      achievementPoints: json['achievement_points'] as int? ?? 0,
      achievements: achievementsRaw
          .map((e) => PlayerAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
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

abstract interface class EconomyRepository {
  Future<PlayerProgression> getProgression(String userUuid);
}
