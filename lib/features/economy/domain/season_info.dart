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
      seasonPoints: _seasonInt(json['season_points']),
      rewardTiers: tiersList
          .whereType<Map>()
          .map((e) => SeasonRewardTier.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static int _seasonInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [slug, seasonPoints];
}

class SeasonRewardTier extends Equatable {
  const SeasonRewardTier({required this.points, required this.reward});

  final int points;
  final String reward;

  factory SeasonRewardTier.fromJson(Map<String, dynamic> json) => SeasonRewardTier(
        points: SeasonInfo._seasonInt(json['points']),
        reward: json['reward'] as String? ?? '',
      );

  @override
  List<Object?> get props => [points, reward];
}
