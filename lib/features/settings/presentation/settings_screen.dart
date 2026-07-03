import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../../shared/widgets/crossball_ui.dart';

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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
              subtitle: _localeLabel(currentLocale, l10n),
              trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
              onTap: () => _showLocalePicker(context, ref, l10n),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  const CrossBallLogo(size: 48),
                  const SizedBox(width: AppSpacing.md),
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

  String _localeLabel(AppLocale locale, AppLocalizations l10n) => switch (locale) {
        AppLocale.system => l10n.localeSystem,
        AppLocale.en => l10n.localeEnglish,
        AppLocale.tr => l10n.localeTurkish,
        AppLocale.de => l10n.localeGerman,
      };

  String _themeLabel(AppThemeMode mode, AppLocalizations l10n) => switch (mode) {
        AppThemeMode.system => l10n.themeSystem,
        AppThemeMode.dark => l10n.themeDark,
        AppThemeMode.light => l10n.themeLight,
      };

  String _themeDescription(AppThemeMode mode, AppLocalizations l10n) => switch (mode) {
        AppThemeMode.system => l10n.themeSystemDesc,
        AppThemeMode.dark => l10n.themeDarkDesc,
        AppThemeMode.light => l10n.themeLightDesc,
      };

  void _showLocalePicker(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cb.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocale.values.map((locale) {
            return ListTile(
              title: Text(_localeLabel(locale, l10n)),
              trailing: ref.watch(localeProvider) == locale
                  ? Icon(Icons.check, color: context.cb.accent)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(locale);
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return ListTile(
              leading: Icon(
                switch (mode) {
                  AppThemeMode.system => Icons.brightness_auto,
                  AppThemeMode.dark => Icons.stadium_outlined,
                  AppThemeMode.light => Icons.grass_outlined,
                },
                color: context.cb.accent,
              ),
              title: Text(_themeLabel(mode, l10n)),
              subtitle: Text(
                _themeDescription(mode, l10n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
