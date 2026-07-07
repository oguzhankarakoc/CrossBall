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
  BannerAd? createBanner(AdPlacement placement);
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

  @override
  bool get isPremium => _isPremium;

  @override
  set isPremium(bool value) => _isPremium = value;

  @override
  Future<void> initialize() async {
    if (!AppConfig.isAdMobEnabled || _isPremium) return;
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
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

  @override
  BannerAd? createBanner(AdPlacement placement) {
    if (!AppConfig.isAdMobEnabled || _isPremium) return null;
    if (placement != AdPlacement.shell &&
        placement != AdPlacement.gameplay &&
        placement != AdPlacement.stats &&
        placement != AdPlacement.result) {
      return null;
    }

    return BannerAd(
      adUnitId: _bannerUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  @override
  Future<bool> showInterstitial() async {
    if (!AppConfig.isAdMobEnabled || _isPremium) return false;
    final ad = _interstitial;
    if (ad == null) return false;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
        completer.complete(false);
      },
    );
    await ad.show();
    return completer.future;
  }

  @override
  Future<bool> showRewarded() async {
    if (!AppConfig.isAdMobEnabled || _isPremium) return true;
    final ad = _rewarded;
    if (ad == null) return false;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
        completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) => completer.complete(true));
    return completer.future;
  }
}

final adsServiceProvider = Provider<AdsService>((ref) => AdsServiceImpl());
