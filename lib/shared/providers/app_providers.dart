import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/challenge/data/challenge_repository_impl.dart';
import '../../features/challenge/domain/challenge.dart';
import '../../features/puzzle/data/puzzle_repository_impl.dart';
import '../../features/puzzle/domain/puzzle_repository.dart';
import '../../features/search/data/search_repository_impl.dart';
import '../../features/search/domain/search.dart';
import '../../features/stats/data/stats_repository_impl.dart';
import '../../features/stats/domain/stats.dart';
import '../../core/cache/offline_cache.dart';
import '../../core/network/supabase_provider.dart';

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

final dailyPuzzleProvider = FutureProvider((ref) async {
  return ref.watch(puzzleRepositoryProvider).getDailyPuzzle();
});

final userStatsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.watch(statsRepositoryProvider).getStats(profile.userUuid);
});
