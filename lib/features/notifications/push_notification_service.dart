import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/config/app_config.dart';
import 'push_token_api.dart';

/// Local streak reminders + FCM token registration hook.
class PushNotificationService {
  PushNotificationService({PushTokenApi? api}) : _api = api ?? PushTokenApi();

  final PushTokenApi _api;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({
    required String userUuid,
    String? locale,
    bool pushOptIn = true,
  }) async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    final iosPlugin =
        _local.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    if (pushOptIn) {
      await _scheduleStreakReminder();
    } else {
      await _local.cancel(1001);
    }

    if (kDebugMode) {
      debugPrint('[Push] initialized for $userUuid opt_in=$pushOptIn');
    }
  }

  Future<void> setPushOptIn(bool enabled) async {
    if (!_initialized) return;
    if (enabled) {
      await _scheduleStreakReminder();
    } else {
      await _local.cancel(1001);
    }
  }

  Future<void> _scheduleStreakReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'streak_reminder',
      'Streak reminders',
      channelDescription: 'Daily puzzle streak reminders',
      importance: Importance.defaultImportance,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.zonedSchedule(
      1001,
      'CrossBall',
      'Keep your streak alive — play today\'s daily puzzle!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Call when FCM/APNs returns a device token.
  Future<void> registerToken({
    required String userUuid,
    required String token,
    String? locale,
    bool? pushOptIn,
    String? appVersion,
  }) async {
    if (!AppConfig.isSupabaseConfigured || token.isEmpty) return;

    final platform = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : 'android';

    await _api.registerToken(
      userUuid: userUuid,
      token: token,
      platform: platform,
      locale: locale,
      pushOptIn: pushOptIn,
      appVersion: appVersion,
    );
  }
}

final pushNotificationService = PushNotificationService();
