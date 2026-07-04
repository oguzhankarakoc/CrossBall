import 'package:equatable/equatable.dart';

class PlayerMission extends Equatable {
  const PlayerMission({
    required this.slug,
    required this.title,
    required this.description,
    required this.period,
    this.progressCurrent = 0,
    this.progressTarget = 1,
    this.isCompleted = false,
    this.rewardXp = 0,
  });

  final String slug;
  final String title;
  final String description;
  final String period;
  final int progressCurrent;
  final int progressTarget;
  final bool isCompleted;
  final int rewardXp;

  double get progressFraction {
    if (progressTarget <= 0) return isCompleted ? 1 : 0;
    return (progressCurrent / progressTarget).clamp(0.0, 1.0);
  }

  factory PlayerMission.fromJson(Map<String, dynamic> json) => PlayerMission(
        slug: json['slug'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        period: json['period'] as String? ?? 'daily',
        progressCurrent: json['progress_current'] as int? ??
            (json['is_completed'] == true ? 1 : 0),
        progressTarget: json['progress_target'] as int? ?? 1,
        isCompleted: json['is_completed'] as bool? ?? false,
        rewardXp: json['reward_xp'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [slug, period, isCompleted, progressCurrent];
}
