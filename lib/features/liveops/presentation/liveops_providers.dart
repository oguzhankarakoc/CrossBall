import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/liveops_repository_impl.dart';
import '../domain/liveops_snapshot.dart';

final liveOpsRepositoryProvider = Provider<LiveOpsRepository>((ref) {
  return LiveOpsRepositoryImpl(
    cache: ref.watch(offlineCacheProvider),
    httpClient: ref.watch(apiHttpClientProvider),
  );
});

final liveOpsSnapshotProvider = FutureProvider<LiveOpsSnapshot>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final localePref = ref.watch(localeProvider);
  final locale = localePref == AppLocale.system
      ? AppLocaleX.deviceDefault().name
      : localePref.name;

  return ref.watch(liveOpsRepositoryProvider).getSnapshot(
        userUuid: profile.userUuid,
        locale: locale,
        platform: LiveOpsRepositoryImpl.platformName(),
      );
});

/// Remotely toggled feature flags with offline-safe defaults.
final featureFlagProvider = Provider.family<bool, String>((ref, slug) {
  final snapshot = ref.watch(liveOpsSnapshotProvider).valueOrNull;
  return snapshot?.isFeatureEnabled(slug) ?? LiveOpsDefaults.isFeatureEnabled(slug);
});

/// Top-priority active announcement, if any.
final topAnnouncementProvider = Provider<LiveOpsAnnouncement?>((ref) {
  final snapshot = ref.watch(liveOpsSnapshotProvider).valueOrNull;
  if (snapshot == null || snapshot.announcements.isEmpty) return null;
  return snapshot.announcements.first;
});
