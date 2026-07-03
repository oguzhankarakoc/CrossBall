import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_remote_data_source.dart';
import '../../features/auth/presentation/auth_providers.dart';

enum AppThemeMode { system, dark, light }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get flutterThemeMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light => ThemeMode.light,
      };

  String get storageValue => name;

  static AppThemeMode fromStorage(String? raw) {
    if (raw == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppThemeMode.system,
    );
  }
}

const _keyThemeMode = 'crossball_theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier(this._ref) : super(AppThemeMode.system) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyThemeMode);
    if (raw != null) {
      state = AppThemeModeX.fromStorage(raw);
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.storageValue);
    await _syncToBackend();
  }

  Future<void> _syncToBackend() async {
    try {
      final uuid = await _ref.read(authRepositoryProvider).getUserUuid();
      if (uuid == null) return;
      await AuthRemoteDataSource().syncPreferences(
        userUuid: uuid,
        themePreference: state.storageValue,
      );
    } catch (_) {}
  }
}
