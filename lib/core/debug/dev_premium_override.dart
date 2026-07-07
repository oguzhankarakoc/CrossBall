import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dev_allowlist.dart';
import '../../features/auth/presentation/auth_providers.dart';

enum DevPremiumMode {
  auto,
  forceFree,
  forcePremium,
}

const _prefsKey = 'crossball_dev_premium_mode';

extension DevPremiumModeStorage on DevPremiumMode {
  String get storageValue => name;

  static DevPremiumMode fromStorage(String? raw) {
    return DevPremiumMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => DevPremiumMode.auto,
    );
  }
}

class DevPremiumModeNotifier extends StateNotifier<DevPremiumMode> {
  DevPremiumModeNotifier() : super(DevPremiumMode.auto) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = DevPremiumModeStorage.fromStorage(prefs.getString(_prefsKey));
  }

  Future<void> setMode(DevPremiumMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.storageValue);
  }
}

final devPremiumModeProvider =
    StateNotifierProvider<DevPremiumModeNotifier, DevPremiumMode>((ref) {
  return DevPremiumModeNotifier();
});

/// True on allowlisted test devices (Oğuzhan iPhone).
final devToolsEnabledProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return DevAllowlist.isDevDevice(userUuid: profile.userUuid);
});
