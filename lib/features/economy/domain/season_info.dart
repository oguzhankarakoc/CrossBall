import 'package:equatable/equatable.dart';

class SeasonInfo extends Equatable {
  const SeasonInfo({
    required this.slug,
    required this.label,
    this.startsAt,
    this.endsAt,
    this.seasonPoints = 0,
    this.rewardTiers = const [],
  });

  final String slug;
  final String label;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int seasonPoints;
  final List<SeasonRewardTier> rewardTiers;

  bool get isActive => slug.isNotEmpty;

  factory SeasonInfo.fromJson(Map<String, dynamic> json) {
    final tiersRaw = json['reward_tiers'] as Map<String, dynamic>?;
    final tiersList = tiersRaw?['tiers'] as List<dynamic>? ?? [];
    return SeasonInfo(
      slug: json['slug'] as String? ?? '',
      label: json['label'] as String? ?? '',
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'] as String)
          : null,
      endsAt:
          json['ends_at'] != null ? DateTime.tryParse(json['ends_at'] as String) : null,
      seasonPoints: json['season_points'] as int? ?? 0,
      rewardTiers: tiersList
          .map((e) => SeasonRewardTier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [slug, seasonPoints];
}

class SeasonRewardTier extends Equatable {
  const SeasonRewardTier({required this.points, required this.reward});

  final int points;
  final String reward;

  factory SeasonRewardTier.fromJson(Map<String, dynamic> json) => SeasonRewardTier(
        points: json['points'] as int? ?? 0,
        reward: json['reward'] as String? ?? '',
      );

  @override
  List<Object?> get props => [points, reward];
}
