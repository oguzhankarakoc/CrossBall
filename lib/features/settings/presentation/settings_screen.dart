import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../../shared/widgets/crossball_ui.dart';

enum AppLocale { system, en, tr, de }

final localeProvider = StateProvider<AppLocale>((ref) => AppLocale.system);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final colors = context.cb;

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.settings),
      body: PitchBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            CrossBallCard(
              icon: Icons.brightness_6_outlined,
              title: l10n.appearance,
              subtitle: _themeLabel(currentTheme, l10n),
              trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
              onTap: () => _showThemePicker(context, ref, l10n),
            ),
            CrossBallCard(
              icon: Icons.language,
              title: l10n.language,
              subtitle: _localeLabel(currentLocale),
              trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
              onTap: () => _showLocalePicker(context, ref),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CrossBallLogo(size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CrossBall v1.0.0', style: Theme.of(context).textTheme.titleMedium),
                        Text(l10n.tagline, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localeLabel(AppLocale locale) => switch (locale) {
        AppLocale.system => 'System default',
        AppLocale.en => 'English',
        AppLocale.tr => 'Türkçe',
        AppLocale.de => 'Deutsch',
      };

  String _themeLabel(AppThemeMode mode, AppLocalizations l10n) => switch (mode) {
        AppThemeMode.system => l10n.themeSystem,
        AppThemeMode.dark => l10n.themeDark,
        AppThemeMode.light => l10n.themeLight,
      };

  void _showLocalePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cb.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocale.values.map((locale) {
            return ListTile(
              title: Text(_localeLabel(locale)),
              trailing: ref.watch(localeProvider) == locale
                  ? Icon(Icons.check, color: context.cb.accent)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).state = locale;
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cb.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return ListTile(
              leading: Icon(
                switch (mode) {
                  AppThemeMode.system => Icons.brightness_auto,
                  AppThemeMode.dark => Icons.dark_mode,
                  AppThemeMode.light => Icons.light_mode,
                },
                color: context.cb.accent,
              ),
              title: Text(_themeLabel(mode, l10n)),
              trailing: ref.watch(themeModeProvider) == mode
                  ? Icon(Icons.check, color: context.cb.accent)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).setMode(mode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
