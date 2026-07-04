import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/challenge/data/challenge_repository_impl.dart';
import '../../features/challenge/domain/challenge.dart';
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
import '../../core/cache/offline_cache.dart';
import '../../core/network/supabase_provider.dart';
import 'locale_provider.dart';

final offlineCacheProvider = Provider<OfflineCache>((ref) => OfflineCache());

final analyticsProvider = Provider<AnalyticsService>((ref) => createAnalyticsService());

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return PuzzleRepositoryImpl(
    api: PuzzleApiService(client: ref.watch(supabaseClientProvider)),
    cache: ref.watch(offlineCacheProvider),
  );
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(
    api: SearchApiService(client: ref.watch(supabaseClientProvider)),
    cache: ref.watch(offlineCacheProvider),
  );
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepositoryImpl();
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepositoryImpl(cache: ref.watch(offlineCacheProvider));
});

final economyRepositoryProvider = Provider<EconomyRepository>((ref) {
  return EconomyRepositoryImpl(cache: ref.watch(offlineCacheProvider));
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl();
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

final footballFactProvider = FutureProvider.family<FootballFact, String>((ref, contextKey) async {
  final localePref = ref.watch(localeProvider);
  final localeCode = switch (localePref) {
    AppLocale.tr => 'tr',
    AppLocale.de => 'de',
    _ => 'en',
  };
  return ref.watch(socialRepositoryProvider).getFootballFact(
        locale: localeCode,
        context: contextKey,
      );
});
