import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_remote_data_source.dart';
import '../../features/auth/presentation/auth_providers.dart';

enum AppLocale { system, en, tr, de }

extension AppLocaleX on AppLocale {
  /// `null` means follow device locale (MaterialApp.locale).
  Locale? get flutterLocale => switch (this) {
        AppLocale.system => null,
        AppLocale.en => const Locale('en'),
        AppLocale.tr => const Locale('tr'),
        AppLocale.de => const Locale('de'),
      };

  String get storageValue => name;

  static AppLocale fromStorage(String? raw) {
    if (raw == null) return AppLocale.system;
    return AppLocale.values.firstWhere(
      (l) => l.name == raw,
      orElse: () => AppLocale.system,
    );
  }

  /// Device language → app locale for first launch / system mode.
  static AppLocale deviceDefault() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return switch (code) {
      'tr' => AppLocale.tr,
      'de' => AppLocale.de,
      'en' => AppLocale.en,
      _ => AppLocale.en,
    };
  }
}

const _keyLocale = 'crossball_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>(
  (ref) => LocaleNotifier(ref),
);

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier(this._ref) : super(AppLocale.system) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLocale);
    if (raw != null) {
      state = AppLocaleX.fromStorage(raw);
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale.storageValue);
    await _syncToBackend();
  }

  Future<void> _syncToBackend() async {
    try {
      final uuid = await _ref.read(authRepositoryProvider).getUserUuid();
      if (uuid == null) return;
      await AuthRemoteDataSource().syncPreferences(
        userUuid: uuid,
        locale: state.storageValue,
      );
    } catch (_) {
      // Offline — local preference still applied.
    }
  }
}

/// Resolved locale for MaterialApp (system → device language with EN fallback).
Locale resolveAppLocale(AppLocale preference) {
  if (preference != AppLocale.system) {
    return preference.flutterLocale ?? const Locale('en');
  }
  final device = PlatformDispatcher.instance.locale;
  final code = device.languageCode;
  if (code == 'tr') return const Locale('tr');
  if (code == 'de') return const Locale('de');
  return const Locale('en');
}
