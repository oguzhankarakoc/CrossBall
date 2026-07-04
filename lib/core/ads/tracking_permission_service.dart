import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// Requests iOS App Tracking Transparency before personalized ads (ASO-01).
Future<void> requestTrackingPermissionIfNeeded() async {
  if (kIsWeb || !Platform.isIOS) return;

  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e, st) {
    debugPrint('ATT request failed: $e\n$st');
  }
}
