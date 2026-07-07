import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Devices/users allowed to use in-app dev premium override (Settings).
abstract final class DevAllowlist {
  /// Oğuzhan test iPhone — user UUID from device secure storage (Jul 2026 logs).
  static const allowlistedUserUuids = {
    '68a155be-b2e2-4821-a81f-4c5e8185e651',
  };

  /// iOS identifierForVendor values for the same physical devices (optional extra gate).
  static const allowlistedIosVendorIds = <String>{};

  static String? _cachedIosVendorId;

  static Future<bool> isDevDevice({String? userUuid}) async {
    if (userUuid != null &&
        allowlistedUserUuids.contains(userUuid.trim().toLowerCase())) {
      return true;
    }

    if (!kIsWeb && Platform.isIOS) {
      final vendorId = await _iosVendorId();
      if (vendorId != null && allowlistedIosVendorIds.contains(vendorId)) {
        return true;
      }
    }

    return false;
  }

  static Future<String?> _iosVendorId() async {
    if (_cachedIosVendorId != null) return _cachedIosVendorId;
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      _cachedIosVendorId = info.identifierForVendor;
      return _cachedIosVendorId;
    } catch (_) {
      return null;
    }
  }
}
