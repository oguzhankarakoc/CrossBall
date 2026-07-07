import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/app_config.dart';
import '../../core/debug/dev_premium_override.dart';
import '../auth/data/auth_remote_data_source.dart';
import '../auth/presentation/auth_providers.dart';

abstract interface class PremiumService {
  Future<void> initialize();
  Future<ProductDetails?> fetchPremiumProduct();
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
  Completer<bool>? _purchaseCompleter;

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

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );

    await _flushPendingTransactions();
  }

  String? _verificationPayload(PurchaseDetails purchase) {
    final server = purchase.verificationData.serverVerificationData.trim();
    if (server.isNotEmpty) return server;
    final local = purchase.verificationData.localVerificationData.trim();
    if (local.isNotEmpty) return local;
    final purchaseId = purchase.purchaseID?.trim();
    if (purchaseId != null && purchaseId.isNotEmpty) return purchaseId;
    return null;
  }

  Future<void> _flushPendingTransactions() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP pending restore on init: $e');
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final userUuid = _pendingUserUuid;
          final verified = userUuid != null
              ? await _verifyWithBackend(
                  userUuid: userUuid,
                  verificationData: _verificationPayload(purchase),
                  source: purchase.verificationData.source,
                )
              : false;
          await _completeStorePurchase(purchase);
          _resolvePurchaseFlow(verified);
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          debugPrint('IAP ${purchase.status}: ${purchase.error}');
          await _completeStorePurchase(purchase);
          _resolvePurchaseFlow(false);
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  Future<void> _completeStorePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void _resolvePurchaseFlow(bool success) {
    final completer = _purchaseCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
    _purchaseCompleter = null;
  }

  Future<bool> _verifyWithBackend({
    required String userUuid,
    String? verificationData,
    String? source,
  }) async {
    if (AppConfig.forceFreeTier) return false;

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
      return true;
    } on SyncUserException catch (e) {
      debugPrint('verify-premium failed: $e');
      return false;
    }
  }

  bool _isDuplicateProductError(PlatformException error) {
    return error.code == 'storekit_duplicate_product_object';
  }

  Completer<bool> _beginPurchaseWait() {
    final existing = _purchaseCompleter;
    if (existing != null && !existing.isCompleted) {
      existing.complete(false);
    }
    final completer = Completer<bool>();
    _purchaseCompleter = completer;
    return completer;
  }

  Future<bool> _waitForPurchaseResult(Completer<bool> completer) {
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _resolvePurchaseFlow(false);
        return false;
      },
    );
  }

  Future<bool> _startStorePurchase(PurchaseParam param) async {
    try {
      return await _iap.buyNonConsumable(purchaseParam: param);
    } on PlatformException catch (e) {
      if (_isDuplicateProductError(e)) {
        debugPrint('IAP pending transaction detected — restoring to finish it');
        await _iap.restorePurchases();
        return true;
      }
      rethrow;
    }
  }

  @override
  Future<ProductDetails?> fetchPremiumProduct() async {
    if (!AppConfig.isIapEnabled) return null;
    await initialize();
    final response = await _iap.queryProductDetails({_productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      debugPrint('IAP product not found: $_productId notFound=${response.notFoundIDs}');
      return null;
    }
    return response.productDetails.first;
  }

  @override
  Future<bool> purchasePremium(String userUuid) async {
    _pendingUserUuid = userUuid;

    if (!AppConfig.isIapEnabled) {
      if (AppConfig.forceFreeTier) return false;
      try {
        await _remote.verifyPremium(
          userUuid: userUuid,
          platform: 'dev',
          productId: _productId,
        );
        _isPremium = true;
        _statusController.add(true);
        return true;
      } on SyncUserException catch (e) {
        debugPrint('verify-premium (dev) failed: $e');
        return false;
      }
    }

    await initialize();

    final available = await _iap.isAvailable();
    if (!available) return false;

    final response = await _iap.queryProductDetails({_productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return false;
    }

    final completer = _beginPurchaseWait();
    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);

    try {
      final started = await _startStorePurchase(param);
      if (!started) {
        _resolvePurchaseFlow(false);
        return false;
      }
      return _waitForPurchaseResult(completer);
    } on PlatformException catch (e) {
      debugPrint('IAP purchase start failed: $e');
      _resolvePurchaseFlow(false);
      return false;
    }
  }

  @override
  Future<bool> restorePurchases(String userUuid) async {
    _pendingUserUuid = userUuid;
    if (!AppConfig.isIapEnabled) return _isPremium;

    await initialize();

    final completer = _beginPurchaseWait();
    await _iap.restorePurchases();

    try {
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _purchaseCompleter = null;
          return _isPremium;
        },
      );
    } catch (_) {
      _purchaseCompleter = null;
      return _isPremium;
    }
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

  final devEnabled = ref.watch(devToolsEnabledProvider).valueOrNull;
  if (devEnabled == true) {
    switch (ref.watch(devPremiumModeProvider)) {
      case DevPremiumMode.forceFree:
        return false;
      case DevPremiumMode.forcePremium:
        return true;
      case DevPremiumMode.auto:
        break;
    }
  }

  final profile = ref.watch(userProfileProvider).valueOrNull;
  final iapPremium = ref.watch(_iapPremiumActiveProvider).valueOrNull ?? false;
  return profile?.isPremium == true || iapPremium;
});

final _iapPremiumActiveProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(premiumServiceProvider) as PremiumServiceImpl;
  yield service.isPremiumActive;
  yield* service.premiumStatusStream;
});
