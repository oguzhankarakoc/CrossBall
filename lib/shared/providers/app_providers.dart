import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../core/network/network_providers.dart';
import '../../features/challenge/data/challenge_repository_impl.dart';
import '../../features/challenge/domain/challenge.dart';
import '../../features/puzzle/data/first_puzzle_coach_store.dart';
import '../../features/puzzle/data/puzzle_repository_impl.dart';
import '../../features/puzzle/domain/puzzle_repository.dart';
import '../../features/search/data/search_repository_impl.dart';
import '../../features/search/domain/search.dart';
import '../../features/economy/data/economy_repository_impl.dart';
import '../../features/economy/domain/club_mastery.dart';
import '../../features/economy/domain/player_mission.dart';
import '../../features/economy/domain/player_progression.dart';
import '../../features/economy/domain/season_info.dart';
import '../../features/social/data/social_repository_impl.dart';
import '../../features/social/domain/social.dart';
import '../../features/stats/data/stats_repository_impl.dart';
import '../../features/stats/domain/stats.dart';
import '../../core/cache/active_puzzle_cache.dart';
import '../../core/cache/daily_completion_store.dart';
import '../../core/cache/offline_cache.dart';
import '../../core/network/supabase_provider.dart';
import 'locale_provider.dart';
import 'session_providers.dart';

final offlineCacheProvider = Provider<OfflineCache>((ref) => OfflineCache());

final firstPuzzleCoachStoreProvider = Provider<FirstPuzzleCoachStore>(
  (ref) => FirstPuzzleCoachStore(),
);

final activePuzzleCacheProvider = Provider<ActivePuzzleCache>(
  (ref) => ActivePuzzleCache(),
);

final dailyCompletionStoreProvider = Provider<DailyCompletionStore>(
  (ref) => DailyCompletionStore(),
);

final analyticsProvider = Provider<AnalyticsService>((ref) => createAnalyticsService());

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  final apiClient = ref.watch(apiHttpClientProvider);
  return PuzzleRepositoryImpl(
    api: PuzzleApiService(
      client: ref.watch(supabaseClientProvider),
      httpClient: apiClient,
    ),
    cache: ref.watch(offlineCacheProvider),
    httpClient: apiClient,
  );
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final apiClient = ref.watch(apiHttpClientProvider);
  return SearchRepositoryImpl(
    api: SearchApiService(httpClient: apiClient),
    cache: ref.watch(offlineCacheProvider),
  );
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepositoryImpl(httpClient: ref.watch(apiHttpClientProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepositoryImpl(
    cache: ref.watch(offlineCacheProvider),
    httpClient: ref.watch(apiHttpClientProvider),
  );
});

final economyRepositoryProvider = Provider<EconomyRepository>((ref) {
  return EconomyRepositoryImpl(
    cache: ref.watch(offlineCacheProvider),
    httpClient: ref.watch(apiHttpClientProvider),
  );
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl(httpClient: ref.watch(apiHttpClientProvider));
});

final playerProgressionProvider = FutureProvider((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(economyRepositoryProvider).getProgression(profile.userUuid);
});

final playerMissionsProvider = FutureProvider<List<PlayerMission>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(economyRepositoryProvider).getMissions(profile.userUuid);
});

final dailyPuzzleProvider = FutureProvider((ref) async {
  return ref.watch(puzzleRepositoryProvider).getDailyPuzzle();
});

final userStatsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(statsRepositoryProvider).getStats(profile.userUuid);
});

/// Server stats + local daily completion guard (UTC day).
final dailyCompletedTodayProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final store = ref.watch(dailyCompletionStoreProvider);
  if (await store.isCompletedToday(userUuid: profile.userUuid)) {
    return true;
  }
  final stats = await ref.watch(userStatsProvider.future);
  if (stats.dailyCompletedToday) {
    await store.markCompletedToday(
      userUuid: profile.userUuid,
      score: stats.todayDailyScore > 0 ? stats.todayDailyScore : null,
    );
    return true;
  }
  return false;
});

/// Today's daily score — local cache first (when finalize lagged), then server stats.
final dailyTodayScoreProvider = FutureProvider<double>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final store = ref.watch(dailyCompletionStoreProvider);
  final local = await store.getTodayScore(userUuid: profile.userUuid);
  if (local != null && local > 0) return local;

  final last = ref.watch(lastCompletedSessionProvider);
  if (last != null &&
      last.mode == 'daily' &&
      last.score > 0 &&
      await store.isCompletedToday(userUuid: profile.userUuid)) {
    return last.score;
  }

  final stats = await ref.watch(userStatsProvider.future);
  return stats.todayDailyScore;
});

final seasonInfoProvider = FutureProvider<SeasonInfo>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(economyRepositoryProvider).getSeason(profile.userUuid);
});

final clubMasteryProvider = FutureProvider<List<ClubMasteryEntry>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(economyRepositoryProvider).getClubMastery(profile.userUuid);
});

final careerHintTasteAvailableProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(economyRepositoryProvider).careerHintTasteAvailable(profile.userUuid);
});

final activityFeedProvider = FutureProvider<List<ActivityEvent>>((ref) async {
  return ref.watch(socialRepositoryProvider).getActivityFeed();
});

final tournamentSnapshotProvider = FutureProvider<TournamentSnapshot>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(socialRepositoryProvider).getTournament(userUuid: profile.userUuid);
});

String resolveFootballFactLocale(AppLocale preference) {
  final resolved = preference == AppLocale.system
      ? AppLocaleX.deviceDefault()
      : preference;
  return switch (resolved) {
    AppLocale.tr => 'tr',
    AppLocale.de => 'de',
    _ => 'en',
  };
}

final footballFactProvider = FutureProvider.family<FootballFact, String>((ref, contextKey) async {
  final localeCode = resolveFootballFactLocale(ref.watch(localeProvider));
  return ref.watch(socialRepositoryProvider).getFootballFact(
        locale: localeCode,
        context: contextKey,
      );
});
