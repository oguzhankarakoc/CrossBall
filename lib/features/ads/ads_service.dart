import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/config/app_config.dart';

enum AdPlacement {
  /// Bottom banner above main tab bar (Home, Practice, Leaderboard, Settings).
  shell,
  /// Bottom banner while a puzzle grid is active.
  gameplay,
  /// Bottom banner on daily / training / challenge result screens.
  result,
  /// Bottom banner on the stats screen.
  stats,
  interstitial,
  rewarded,
}

abstract interface class AdsService {
  Future<void> initialize();
  Future<BannerAd?> createAdaptiveBanner({
    required AdPlacement placement,
    required int width,
  });
  Future<bool> showInterstitial();
  Future<bool> showRewarded();
  bool get isPremium;
  set isPremium(bool value);
}

class AdsServiceImpl implements AdsService {
  AdsServiceImpl();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _isPremium = false;
  bool _sdkReady = false;
  Future<RewardedAd?>? _rewardedLoading;
  Future<InterstitialAd?>? _interstitialLoading;

  @override
  bool get isPremium => _isPremium;

  @override
  set isPremium(bool value) => _isPremium = value;

  @override
  Future<void> initialize() async {
    if (!AppConfig.isAdMobEnabled || _isPremium) return;
    if (!_sdkReady) {
      await MobileAds.instance.initialize();
      _sdkReady = true;
    }
    unawaited(_ensureInterstitialLoaded());
    unawaited(_ensureRewardedLoaded());
  }

  String _bannerUnitId() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppConfig.adMobBannerIos;
    }
    return AppConfig.adMobBannerAndroid;
  }

  String _interstitialUnitId() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppConfig.adMobInterstitialIos;
    }
    return AppConfig.adMobInterstitialAndroid;
  }

  String _rewardedUnitId() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppConfig.adMobRewardedIos;
    }
    return AppConfig.adMobRewardedAndroid;
  }

  bool _supportsBanner(AdPlacement placement) {
    return placement == AdPlacement.shell ||
        placement == AdPlacement.gameplay ||
        placement == AdPlacement.stats ||
        placement == AdPlacement.result;
  }

  @override
  Future<BannerAd?> createAdaptiveBanner({
    required AdPlacement placement,
    required int width,
  }) async {
    if (!AppConfig.isAdMobEnabled || _isPremium || !_supportsBanner(placement)) {
      return null;
    }
    if (!_sdkReady) {
      await initialize();
    }

    final safeWidth = width.clamp(320, 728);
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      safeWidth,
    );
    final size = adaptiveSize ?? AdSize.banner;

    final completer = Completer<BannerAd?>();
    late BannerAd banner;
    banner = BannerAd(
      adUnitId: _bannerUnitId(),
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(banner);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            debugPrint('Banner failed to load ($placement): $error');
          }
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    banner.load();
    return completer.future;
  }

  Future<InterstitialAd?> _ensureInterstitialLoaded() {
    if (!AppConfig.isAdMobEnabled || _isPremium) {
      return Future.value(null);
    }
    if (_interstitial != null) return Future.value(_interstitial);
    if (_interstitialLoading != null) return _interstitialLoading!;

    final completer = Completer<InterstitialAd?>();
    _interstitialLoading = completer.future;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoading = null;
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _interstitialLoading = null;
          if (kDebugMode) {
            debugPrint('Interstitial failed to load: $error');
          }
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _interstitialLoading = null;
        return null;
      },
    );
  }

  Future<RewardedAd?> _ensureRewardedLoaded() {
    if (!AppConfig.isAdMobEnabled || _isPremium) {
      return Future.value(null);
    }
    if (_rewarded != null) return Future.value(_rewarded);
    if (_rewardedLoading != null) return _rewardedLoading!;

    final completer = Completer<RewardedAd?>();
    _rewardedLoading = completer.future;
    RewardedAd.load(
      adUnitId: _rewardedUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoading = null;
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _rewarded = null;
          _rewardedLoading = null;
          if (kDebugMode) {
            debugPrint('Rewarded failed to load: $error');
          }
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _rewardedLoading = null;
        return null;
      },
    );
  }

  @override
  Future<bool> showInterstitial() async {
    if (!AppConfig.isAdMobEnabled || _isPremium) return false;
    if (!_sdkReady) await initialize();

    var ad = _interstitial ?? await _ensureInterstitialLoaded();
    if (ad == null) return false;
    _interstitial = null;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_ensureInterstitialLoaded());
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (kDebugMode) {
          debugPrint('Interstitial failed to show: $error');
        }
        unawaited(_ensureInterstitialLoaded());
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show();
    return completer.future;
  }

  @override
  Future<bool> showRewarded() async {
    if (!AppConfig.isAdMobEnabled || _isPremium) return true;
    if (!_sdkReady) await initialize();

    var ad = _rewarded ?? await _ensureRewardedLoaded();
    if (ad == null) return false;
    _rewarded = null;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_ensureRewardedLoaded());
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (kDebugMode) {
          debugPrint('Rewarded failed to show: $error');
        }
        unawaited(_ensureRewardedLoaded());
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    return completer.future;
  }
}

final adsServiceProvider = Provider<AdsService>((ref) => AdsServiceImpl());
