import 'package:equatable/equatable.dart';

/// Safe defaults when LiveOps backend is unavailable (failsafe design).
abstract final class LiveOpsDefaults {
  static const cacheTtlSeconds = 300;

  static const defaultFeatureFlags = <String, bool>{
    'friend_challenges': true,
    'grid_4x4': true,
    'new_themes': true,
    'experimental_puzzle_generator': false,
    'special_events': true,
    'premium_features': true,
    'tournament_mode': true,
    'friend_activity_feed': true,
    'timeline_mode': true,
    'ai_features': true,
  };

  static bool isFeatureEnabled(String slug) =>
      defaultFeatureFlags[slug] ?? true;
}

class LiveOpsAnnouncement extends Equatable {
  const LiveOpsAnnouncement({
    required this.slug,
    required this.type,
    required this.title,
    required this.body,
    this.buttonLabel,
    this.imageUrl,
    this.deepLink,
    this.priority = 0,
  });

  final String slug;
  final String type;
  final String title;
  final String body;
  final String? buttonLabel;
  final String? imageUrl;
  final String? deepLink;
  final int priority;

  factory LiveOpsAnnouncement.fromJson(Map<String, dynamic> json) =>
      LiveOpsAnnouncement(
        slug: json['slug'] as String,
        type: json['type'] as String? ?? 'info',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        buttonLabel: json['button_label'] as String?,
        imageUrl: json['image_url'] as String?,
        deepLink: json['deep_link'] as String?,
        priority: json['priority'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [slug, title];
}

class LiveOpsEvent extends Equatable {
  const LiveOpsEvent({
    required this.slug,
    required this.eventType,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.startsAt,
    this.endsAt,
  });

  final String slug;
  final String eventType;
  final String title;
  final String description;
  final String? ctaLabel;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory LiveOpsEvent.fromJson(Map<String, dynamic> json) => LiveOpsEvent(
        slug: json['slug'] as String,
        eventType: json['event_type'] as String? ?? 'limited',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        ctaLabel: json['cta_label'] as String?,
        startsAt: json['starts_at'] != null
            ? DateTime.tryParse(json['starts_at'] as String)
            : null,
        endsAt: json['ends_at'] != null
            ? DateTime.tryParse(json['ends_at'] as String)
            : null,
      );

  @override
  List<Object?> get props => [slug, title];
}

class LiveOpsCommunityGoal extends Equatable {
  const LiveOpsCommunityGoal({
    required this.slug,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.progressPct,
    this.isUnlocked = false,
  });

  final String slug;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final double progressPct;
  final bool isUnlocked;

  factory LiveOpsCommunityGoal.fromJson(Map<String, dynamic> json) =>
      LiveOpsCommunityGoal(
        slug: json['slug'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        targetValue: json['target_value'] as int? ?? 0,
        currentValue: json['current_value'] as int? ?? 0,
        progressPct: (json['progress_pct'] as num?)?.toDouble() ?? 0,
        isUnlocked: json['is_unlocked'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [slug, progressPct];
}

class LiveOpsSnapshot extends Equatable {
  const LiveOpsSnapshot({
    this.config = const {},
    this.featureFlags = LiveOpsDefaults.defaultFeatureFlags,
    this.activeEvents = const [],
    this.announcements = const [],
    this.collections = const [],
    this.communityGoals = const [],
    this.experiments = const {},
    this.contentRotation = const {},
    this.emergency = const {},
    this.fetchedAt,
    this.cacheTtlSeconds = LiveOpsDefaults.cacheTtlSeconds,
  });

  final Map<String, dynamic> config;
  final Map<String, bool> featureFlags;
  final List<LiveOpsEvent> activeEvents;
  final List<LiveOpsAnnouncement> announcements;
  final List<Map<String, dynamic>> collections;
  final List<LiveOpsCommunityGoal> communityGoals;
  final Map<String, String> experiments;
  final Map<String, dynamic> contentRotation;
  final Map<String, dynamic> emergency;
  final DateTime? fetchedAt;
  final int cacheTtlSeconds;

  bool isFeatureEnabled(String slug) => featureFlags[slug] ?? LiveOpsDefaults.isFeatureEnabled(slug);

  bool get isMaintenanceMode => emergency['maintenance_mode'] == true;

  bool get canStartNewSessions => emergency['disable_new_sessions'] != true;

  Map<String, dynamic>? get gameplayConfig =>
      config['gameplay'] as Map<String, dynamic>?;

  Map<String, dynamic>? get adsConfig => config['ads'] as Map<String, dynamic>?;

  factory LiveOpsSnapshot.fromJson(Map<String, dynamic> json) {
    final flagsRaw = json['feature_flags'] as Map<String, dynamic>? ?? {};
    final flags = flagsRaw.map((k, v) => MapEntry(k, v == true));

    return LiveOpsSnapshot(
      config: (json['config'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v)),
      featureFlags: {...LiveOpsDefaults.defaultFeatureFlags, ...flags},
      activeEvents: (json['active_events'] as List<dynamic>? ?? [])
          .map((e) => LiveOpsEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      announcements: (json['announcements'] as List<dynamic>? ?? [])
          .map((e) => LiveOpsAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList(),
      collections: (json['collections'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      communityGoals: (json['community_goals'] as List<dynamic>? ?? [])
          .map((e) => LiveOpsCommunityGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      experiments: (json['experiments'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
      contentRotation:
          json['content_rotation'] as Map<String, dynamic>? ?? {},
      emergency: json['emergency'] as Map<String, dynamic>? ?? {},
      fetchedAt: json['fetched_at'] != null
          ? DateTime.tryParse(json['fetched_at'] as String)
          : null,
      cacheTtlSeconds:
          json['cache_ttl_seconds'] as int? ?? LiveOpsDefaults.cacheTtlSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'config': config,
        'feature_flags': featureFlags,
        'active_events': activeEvents
            .map((e) => {
                  'slug': e.slug,
                  'event_type': e.eventType,
                  'title': e.title,
                  'description': e.description,
                })
            .toList(),
        'announcements': announcements
            .map((a) => {
                  'slug': a.slug,
                  'type': a.type,
                  'title': a.title,
                  'body': a.body,
                  'button_label': a.buttonLabel,
                  'deep_link': a.deepLink,
                  'priority': a.priority,
                })
            .toList(),
        'collections': collections,
        'community_goals': communityGoals
            .map((g) => {
                  'slug': g.slug,
                  'title': g.title,
                  'description': g.description,
                  'target_value': g.targetValue,
                  'current_value': g.currentValue,
                  'progress_pct': g.progressPct,
                  'is_unlocked': g.isUnlocked,
                })
            .toList(),
        'experiments': experiments,
        'content_rotation': contentRotation,
        'emergency': emergency,
        'fetched_at': fetchedAt?.toIso8601String(),
        'cache_ttl_seconds': cacheTtlSeconds,
      };

  static LiveOpsSnapshot fallback() => const LiveOpsSnapshot();

  @override
  List<Object?> get props => [featureFlags, announcements.length];
}

abstract interface class LiveOpsRepository {
  Future<LiveOpsSnapshot> getSnapshot({
    required String userUuid,
    required String locale,
    required String platform,
    String country = '',
    String appVersion = '1.0.0',
  });
}
