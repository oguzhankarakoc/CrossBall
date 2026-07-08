import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration loaded from `.env`.
abstract final class AppConfig {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env may be missing in some Xcode builds — app falls back to demo mode.
    }
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Direct HTTP calls to Edge Functions need both apikey and Authorization.
  static Map<String, String> get supabaseFunctionHeaders => {
        'Content-Type': 'application/json',
        if (isSupabaseConfigured) ...{
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      };

  static bool get isAdMobEnabled =>
      dotenv.env['ADMOB_ENABLED']?.trim().toLowerCase() != 'false';

  static bool get useTestAds =>
      dotenv.env['ADMOB_USE_TEST_ADS']?.trim().toLowerCase() != 'false';

  static String get adMobBannerAndroid =>
      dotenv.env['ADMOB_BANNER_ANDROID']?.trim() ??
      'ca-app-pub-3940256099942544/6300978111';

  static String get adMobBannerIos =>
      dotenv.env['ADMOB_BANNER_IOS']?.trim() ??
      'ca-app-pub-3940256099942544/2934735716';

  static String get adMobInterstitialAndroid =>
      dotenv.env['ADMOB_INTERSTITIAL_ANDROID']?.trim() ??
      'ca-app-pub-3940256099942544/1033173712';

  static String get adMobInterstitialIos =>
      dotenv.env['ADMOB_INTERSTITIAL_IOS']?.trim() ??
      'ca-app-pub-3940256099942544/4411468910';

  static String get adMobRewardedAndroid =>
      dotenv.env['ADMOB_REWARDED_ANDROID']?.trim() ??
      'ca-app-pub-3940256099942544/5224354917';

  static String get adMobRewardedIos =>
      dotenv.env['ADMOB_REWARDED_IOS']?.trim() ??
      'ca-app-pub-3940256099942544/1712485313';

  // PostHog analytics
  static String get postHogApiKey => dotenv.env['POSTHOG_API_KEY']?.trim() ?? '';
  static String get postHogHost =>
      dotenv.env['POSTHOG_HOST']?.trim() ?? 'https://us.i.posthog.com';

  static bool get isPostHogConfigured => postHogApiKey.isNotEmpty;

  // In-app purchase
  static bool get isIapEnabled =>
      dotenv.env['IAP_ENABLED']?.trim().toLowerCase() == 'true';

  /// When true, forces free tier on this build/device (overrides IAP + remote premium).
  static bool get forceFreeTier =>
      dotenv.env['FORCE_FREE_TIER']?.trim().toLowerCase() == 'true';

  static String get iapPremiumProductIdIos =>
      dotenv.env['IAP_PREMIUM_PRODUCT_ID_IOS']?.trim() ?? 'crossball_premium';

  static String get iapPremiumProductIdAndroid =>
      dotenv.env['IAP_PREMIUM_PRODUCT_ID_ANDROID']?.trim() ?? 'crossball_premium';

  // Remote push (FCM) — optional; set REMOTE_PUSH_ENABLED=true after Firebase setup
  static bool get isRemotePushEnabled =>
      dotenv.env['REMOTE_PUSH_ENABLED']?.trim().toLowerCase() == 'true';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID']?.trim() ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim() ?? '';

  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY']?.trim() ?? '';

  static String get firebaseIosAppId =>
      dotenv.env['FIREBASE_IOS_APP_ID']?.trim() ?? '';

  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY']?.trim() ?? '';

  static String get firebaseAndroidAppId =>
      dotenv.env['FIREBASE_ANDROID_APP_ID']?.trim() ?? '';

  static bool get isFirebaseConfigured {
    if (firebaseProjectId.isEmpty || firebaseMessagingSenderId.isEmpty) {
      return false;
    }
    if (kIsWeb) return false;
    if (!kIsWeb && Platform.isIOS) {
      return firebaseIosApiKey.isNotEmpty && firebaseIosAppId.isNotEmpty;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return firebaseAndroidApiKey.isNotEmpty && firebaseAndroidAppId.isNotEmpty;
    }
    return false;
  }

  static FirebaseOptions? get firebaseOptions {
    if (!isFirebaseConfigured || kIsWeb) return null;
    if (Platform.isIOS) {
      return FirebaseOptions(
        apiKey: firebaseIosApiKey,
        appId: firebaseIosAppId,
        messagingSenderId: firebaseMessagingSenderId,
        projectId: firebaseProjectId,
        iosBundleId: 'com.crossball.crossball',
      );
    }
    if (Platform.isAndroid) {
      return FirebaseOptions(
        apiKey: firebaseAndroidApiKey,
        appId: firebaseAndroidAppId,
        messagingSenderId: firebaseMessagingSenderId,
        projectId: firebaseProjectId,
      );
    }
    return null;
  }
}
