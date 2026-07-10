import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../../features/notifications/push_token_api.dart';

/// Registers FCM device tokens with Supabase when [AppConfig.isRemotePushEnabled].
class RemotePushService {
  RemotePushService({PushTokenApi? api}) : _api = api ?? PushTokenApi();

  final PushTokenApi _api;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _firebaseReady = false;
  bool _listenersAttached = false;

  Future<void> start({
    required String userUuid,
    required bool pushOptIn,
    String? locale,
    String? appVersion,
  }) async {
    if (!AppConfig.isRemotePushEnabled || !AppConfig.isFirebaseConfigured) {
      return;
    }

    try {
      await _ensureFirebase();
    } catch (e, st) {
      debugPrint('[RemotePush] Firebase init failed: $e\n$st');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _attachMessageListeners(messaging);

    if (kDebugMode && Platform.isIOS) {
      final apns = await messaging.getAPNSToken();
      debugPrint('[RemotePush] APNs token: ${apns ?? "null (wait/rebuild)"}');
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    if (!pushOptIn) return;

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(
        userUuid: userUuid,
        token: token,
        locale: locale,
        pushOptIn: pushOptIn,
        appVersion: appVersion,
      );
    }

    _tokenRefreshSub = messaging.onTokenRefresh.listen(
      (token) => _registerToken(
        userUuid: userUuid,
        token: token,
        locale: locale,
        pushOptIn: pushOptIn,
        appVersion: appVersion,
      ),
      onError: (Object e) => debugPrint('[RemotePush] token refresh error: $e'),
    );
  }

  void _attachMessageListeners(FirebaseMessaging messaging) {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[RemotePush] foreground message: '
        '${message.notification?.title ?? message.data}',
      );
    });

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[RemotePush] opened from notification: ${message.data}');
    });

    messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[RemotePush] initial message: ${message.data}');
      }
    });
  }

  Future<void> updateOptIn({
    required String userUuid,
    required bool pushOptIn,
    String? locale,
    String? appVersion,
  }) async {
    await start(
      userUuid: userUuid,
      pushOptIn: pushOptIn,
      locale: locale,
      appVersion: appVersion,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundSub?.cancel();
    _foregroundSub = null;
    await _openedSub?.cancel();
    _openedSub = null;
    _listenersAttached = false;
  }

  Future<void> _ensureFirebase() async {
    if (_firebaseReady) return;

    final options = AppConfig.firebaseOptions;
    if (options == null) {
      throw StateError('firebase_options_missing');
    }

    try {
      await Firebase.initializeApp(options: options);
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }

    _firebaseReady = true;
  }

  Future<void> _registerToken({
    required String userUuid,
    required String token,
    String? locale,
    bool? pushOptIn,
    String? appVersion,
  }) async {
    try {
      await _api.registerToken(
        userUuid: userUuid,
        token: token,
        platform: kIsWeb
            ? 'web'
            : Platform.isIOS
                ? 'ios'
                : 'android',
        locale: locale,
        pushOptIn: pushOptIn,
        appVersion: appVersion,
      );
      if (kDebugMode) {
        debugPrint('[RemotePush] token registered (${token.length} chars)');
      }
    } on PushTokenException catch (e) {
      debugPrint('[RemotePush] register failed: $e');
    }
  }
}

final remotePushService = RemotePushService();
