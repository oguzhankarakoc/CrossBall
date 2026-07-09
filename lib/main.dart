import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/ads/tracking_permission_service.dart';
import 'core/club_identity/club_metadata_loader.dart';
import 'core/config/app_config.dart';
import 'core/crash/crash_reporting_service.dart';
import 'core/debug/crossball_debug_log.dart';
import 'core/sync/offline_sync_service.dart';
import 'features/ads/ads_service.dart';
import 'features/auth/domain/user_profile.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/notifications/push_notification_service.dart';
import 'features/premium/premium_service.dart';
import 'shared/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await lockPortraitOrientation();

  try {
    await AppConfig.load();
    cbDebugConfigSnapshot();
    await ClubMetadataLoader.loadBundled();
  } catch (e, st) {
    debugPrint('AppConfig.load failed: $e\n$st');
    cbDebugError('Config', 'AppConfig.load failed', e, st);
  }

  if (AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey, // ignore: deprecated_member_use
      ).timeout(const Duration(seconds: 10));
      cbDebug('Config', 'Supabase.initialize OK');
    } catch (e, st) {
      debugPrint('Supabase.initialize failed: $e\n$st');
      cbDebugError('Config', 'Supabase.initialize failed', e, st);
    }
  } else {
    cbDebug('Config', 'Supabase skipped — URL or anon key missing in .env');
  }

  final container = ProviderContainer();
  installCrashHandlers(createCrashReportingService(container.read(analyticsProvider)));

  // One-time migration: remove legacy cross-session search picks (competitive integrity).
  unawaited(container.read(offlineCacheProvider).clearRecentPicks());

  try {
    final profile = await container.read(userProfileProvider.future);
    await container.read(authRepositoryProvider).syncDeviceProfile(
          pushOptIn: profile.pushOptIn,
        );
    await pushNotificationService.initialize(
      userUuid: profile.userUuid,
      pushOptIn: profile.pushOptIn,
    );
    final analytics = container.read(analyticsProvider);
    await analytics.identify(
      profile.userUuid,
      traits: {
        'is_premium': profile.isPremium,
        if (profile.displayName != null) 'display_name': profile.displayName,
      },
    );
    unawaited(analytics.track('app_opened'));
  } catch (e, st) {
    debugPrint('Startup profile sync failed: $e\n$st');
  }

  if (AppConfig.isAdMobEnabled) {
    try {
      await requestTrackingPermissionIfNeeded();
      final ads = container.read(adsServiceProvider);
      final isPremium = container.read(isPremiumProvider);
      ads.isPremium = isPremium;
      await ads.initialize();
    } catch (e, st) {
      debugPrint('AdMob initialize failed: $e\n$st');
    }
  }

  try {
    await container.read(premiumServiceProvider).initialize();
  } catch (e, st) {
    debugPrint('Premium init failed: $e\n$st');
  }

  try {
    OfflineSyncService(cache: container.read(offlineCacheProvider)).startListening();
  } catch (e, st) {
    debugPrint('OfflineSync start failed: $e\n$st');
  }

  container.dispose();

  runApp(const ProviderScope(child: PremiumAdsSync(child: CrossBallApp())));
}

/// Keeps ads + analytics traits in sync with profile/IAP state.
class PremiumAdsSync extends ConsumerWidget {
  const PremiumAdsSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(isPremiumProvider, (previous, isPremium) {
      ref.read(adsServiceProvider).isPremium = isPremium;
      if (previous != isPremium) {
        _syncAnalyticsIdentity(ref, isPremium: isPremium);
      }
    });
    ref.listen(userProfileProvider, (previous, next) {
      final prevProfile = previous?.valueOrNull;
      final profile = next.valueOrNull;
      if (profile == null) return;
      if (prevProfile?.displayName != profile.displayName ||
          prevProfile?.isPremium != profile.isPremium) {
        _syncAnalyticsIdentity(
          ref,
          isPremium: ref.read(isPremiumProvider),
          profile: profile,
        );
      }
    });
    return child;
  }

  void _syncAnalyticsIdentity(
    WidgetRef ref, {
    required bool isPremium,
    UserProfile? profile,
  }) {
    profile ??= ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;
    unawaited(
      ref.read(analyticsProvider).identify(
            profile.userUuid,
            traits: {
              'is_premium': isPremium,
              if (profile.displayName != null) 'display_name': profile.displayName,
            },
          ),
    );
  }
}
