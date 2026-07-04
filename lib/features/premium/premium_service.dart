import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/app_config.dart';
import '../auth/data/auth_remote_data_source.dart';
import '../auth/presentation/auth_providers.dart';

abstract interface class PremiumService {
  Future<void> initialize();
  Future<bool> purchasePremium(String userUuid);
  Future<bool> restorePurchases(String userUuid);
  bool get isPremiumActive;
  Stream<bool> get premiumStatusStream;
}

class PremiumServiceImpl implements PremiumService {
  PremiumServiceImpl({
    InAppPurchase? iap,
    AuthRemoteDataSource? remote,
  })  : _iap = iap ?? InAppPurchase.instance,
        _remote = remote ?? AuthRemoteDataSource();

  final InAppPurchase _iap;
  final AuthRemoteDataSource _remote;
  final _statusController = StreamController<bool>.broadcast();

  bool _isPremium = false;
  String? _pendingUserUuid;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  bool get isPremiumActive => _isPremium;

  @override
  Stream<bool> get premiumStatusStream => _statusController.stream;

  String get _productId {
    if (Platform.isIOS) return AppConfig.iapPremiumProductIdIos;
    return AppConfig.iapPremiumProductIdAndroid;
  }

  @override
  Future<void> initialize() async {
    if (!AppConfig.isIapEnabled) return;

    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final userUuid = _pendingUserUuid;
        if (userUuid != null) {
          await _verifyWithBackend(
            userUuid: userUuid,
            verificationData: purchase.verificationData.serverVerificationData,
            source: purchase.verificationData.source,
          );
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('IAP error: ${purchase.error}');
      }
    }
  }

  Future<void> _verifyWithBackend({
    required String userUuid,
    String? verificationData,
    String? source,
  }) async {
    if (AppConfig.forceFreeTier) return;

    try {
      await _remote.verifyPremium(
        userUuid: userUuid,
        platform: Platform.isIOS ? 'ios' : 'android',
        productId: _productId,
        verificationData: verificationData,
        source: source,
      );
      _isPremium = true;
      _statusController.add(true);
    } on SyncUserException catch (e) {
      debugPrint('verify-premium failed: $e');
    }
  }

  @override
  Future<bool> purchasePremium(String userUuid) async {
    _pendingUserUuid = userUuid;

    if (!AppConfig.isIapEnabled) {
      if (AppConfig.forceFreeTier) return false;
      await _remote.verifyPremium(
        userUuid: userUuid,
        platform: 'dev',
        productId: _productId,
      );
      _isPremium = true;
      _statusController.add(true);
      return true;
    }

    final available = await _iap.isAvailable();
    if (!available) return false;

    final response = await _iap.queryProductDetails({_productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return false;
    }

    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<bool> restorePurchases(String userUuid) async {
    _pendingUserUuid = userUuid;
    if (!AppConfig.isIapEnabled) return _isPremium;
    await _iap.restorePurchases();
    return _isPremium;
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

final premiumServiceProvider = Provider<PremiumService>((ref) {
  final service = PremiumServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

final isPremiumProvider = Provider<bool>((ref) {
  if (AppConfig.forceFreeTier) return false;
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final iapPremium = ref.watch(_iapPremiumActiveProvider).valueOrNull ?? false;
  return profile?.isPremium == true || iapPremium;
});

final _iapPremiumActiveProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(premiumServiceProvider) as PremiumServiceImpl;
  yield service.isPremiumActive;
  yield* service.premiumStatusStream;
});
