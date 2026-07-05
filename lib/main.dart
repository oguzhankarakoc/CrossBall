import 'dart:async';

import 'package:flutter/foundation.dart';
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

  try {
    final profile = await container.read(userProfileProvider.future);
    await container.read(authRepositoryProvider).syncDeviceProfile(
          pushOptIn: profile.pushOptIn,
        );
    await pushNotificationService.initialize(
      userUuid: profile.userUuid,
      pushOptIn: profile.pushOptIn,
    );
    await container.read(analyticsProvider).identify(
          profile.userUuid,
          traits: {
            'is_premium': profile.isPremium,
            if (profile.displayName != null) 'display_name': profile.displayName,
          },
        );
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

/// Keeps ads premium flag in sync with profile/IAP state.
class PremiumAdsSync extends ConsumerWidget {
  const PremiumAdsSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(isPremiumProvider, (_, isPremium) {
      ref.read(adsServiceProvider).isPremium = isPremium;
    });
    return child;
  }
}
