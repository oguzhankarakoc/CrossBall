import 'package:equatable/equatable.dart';

import '../../../core/utils/player_display_name.dart';

class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.id,
    required this.userUuid,
    required this.displayName,
    required this.eventType,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String userUuid;
  final String displayName;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  /// Nickname when set, otherwise `Player #XXXX` derived from [userUuid].
  String get displayLabel => resolvePlayerDisplayLabel(
        displayName: displayName,
        userUuid: userUuid,
      );

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        id: json['id'] as String,
        userUuid: json['user_uuid'] as String? ?? '',
        displayName: json['display_name'] as String? ?? kAnonymousPlayerPrefix,
        eventType: json['event_type'] as String? ?? '',
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id];
}

class FootballFact extends Equatable {
  const FootballFact({required this.factKey, required this.text});

  final String factKey;
  final String text;

  factory FootballFact.fromJson(Map<String, dynamic> json) => FootballFact(
        factKey: json['fact_key'] as String? ?? '',
        text: json['fact'] as String? ?? '',
      );

  bool get isValid => text.isNotEmpty;

  @override
  List<Object?> get props => [factKey, text];
}

class TournamentEntry extends Equatable {
  const TournamentEntry({
    required this.rank,
    required this.userUuid,
    required this.displayName,
    required this.bestScore,
    required this.sessionsCount,
  });

  final int rank;
  final String userUuid;
  final String displayName;
  final double bestScore;
  final int sessionsCount;

  String get displayLabel => resolvePlayerDisplayLabel(
        displayName: displayName,
        userUuid: userUuid,
      );

  factory TournamentEntry.fromJson(Map<String, dynamic> json) => TournamentEntry(
        rank: json['rank'] as int? ?? 0,
        userUuid: json['user_uuid'] as String? ?? '',
        displayName: json['display_name'] as String? ?? kAnonymousPlayerPrefix,
        bestScore: (json['best_score'] as num?)?.toDouble() ?? 0,
        sessionsCount: json['sessions_count'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [rank, userUuid, displayName];
}

class TournamentSnapshot extends Equatable {
  const TournamentSnapshot({
    this.slug = '',
    this.title = '',
    this.description = '',
    this.entries = const [],
    this.userRank,
    this.endsAt,
  });

  final String slug;
  final String title;
  final String description;
  final List<TournamentEntry> entries;
  final int? userRank;
  final DateTime? endsAt;

  bool get isActive => slug.isNotEmpty;

  factory TournamentSnapshot.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'] as List<dynamic>? ?? [];
    return TournamentSnapshot(
      slug: json['slug'] as String? ?? json['tournament_slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      entries: entriesRaw
          .map((e) => TournamentEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      userRank: json['user_rank'] as int?,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [slug, entries.length, userRank];
}

class CareerTimelineEntry extends Equatable {
  const CareerTimelineEntry({
    required this.clubName,
    this.startYear,
    this.endYear,
    this.highlight = false,
  });

  final String clubName;
  final int? startYear;
  final int? endYear;
  final bool highlight;

  factory CareerTimelineEntry.fromJson(Map<String, dynamic> json) =>
      CareerTimelineEntry(
        clubName: json['club_name'] as String? ?? '',
        startYear: json['start_year'] as int?,
        endYear: json['end_year'] as int?,
        highlight: json['highlight'] as bool? ?? false,
      );

  String yearLabel(String presentLabel) {
    if (startYear == null && endYear == null) return '';
    if (endYear == null) return '$startYear–$presentLabel';
    if (startYear == endYear) return '$startYear';
    return '$startYear–$endYear';
  }

  @override
  List<Object?> get props => [clubName, startYear, endYear];
}

class CareerTimeline extends Equatable {
  const CareerTimeline({
    required this.playerName,
    required this.entries,
  });

  final String playerName;
  final List<CareerTimelineEntry> entries;

  factory CareerTimeline.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] as List<dynamic>? ?? [];
    return CareerTimeline(
      playerName: json['player_name'] as String? ?? 'Player',
      entries: raw
          .map((e) => CareerTimelineEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [playerName, entries];
}

abstract interface class SocialRepository {
  Future<List<ActivityEvent>> getActivityFeed({int limit = 15});
  Future<FootballFact> getFootballFact({required String locale, String context = 'intersection'});
  Future<TournamentSnapshot> getTournament({required String userUuid, int limit = 25});
  Future<CareerTimeline> getCareerTimeline({
    required String playerId,
    required String rowClubId,
    required String colClubId,
  });
}
