import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../../shared/providers/theme_mode_provider.dart';

/// Resolves MaterialApp theme triple from [AppThemeMode].
({ThemeData light, ThemeData dark, ThemeMode mode}) resolveAppThemes(AppThemeMode pref) {
  final light = switch (pref) {
    AppThemeMode.lightClassic => AppTheme.lightClassic(),
    _ => AppTheme.lightPitch(),
  };

  final dark = switch (pref) {
    AppThemeMode.darkGold => AppTheme.darkGold(),
    _ => AppTheme.darkStadium(),
  };

  final mode = switch (pref) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light || AppThemeMode.lightClassic => ThemeMode.light,
    AppThemeMode.dark || AppThemeMode.darkGold => ThemeMode.dark,
  };

  return (light: light, dark: dark, mode: mode);
}
