import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/validation/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_remote_data_source.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notifications/push_notification_service.dart';
import '../../../features/premium/premium_service.dart';
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
    final profileAsync = ref.watch(userProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.settings),
      body: PitchBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            profileAsync.when(
              data: (profile) => CrossBallCard(
                icon: Icons.person_outline_rounded,
                title: l10n.playerNickname,
                subtitle: profile.displayLabel,
                trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                onTap: () => _editNickname(context, ref, profile.displayName),
              ),
              loading: () => CrossBallCard(
                icon: Icons.person_outline_rounded,
                title: l10n.playerNickname,
                subtitle: l10n.comingSoon,
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            CrossBallCard(
              icon: Icons.notifications_outlined,
              title: l10n.pushNotifications,
              subtitle: profileAsync.valueOrNull?.pushOptIn == true
                  ? l10n.pushNotificationsOn
                  : l10n.pushNotificationsOff,
              trailing: Switch.adaptive(
                value: profileAsync.valueOrNull?.pushOptIn ?? true,
                onChanged: profileAsync.isLoading
                    ? null
                    : (value) => _setPushOptIn(context, ref, value),
              ),
            ),
            CrossBallCard(
              icon: Icons.brightness_6_outlined,
              title: l10n.appearance,
              subtitle: _themeLabel(currentTheme, l10n),
              trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
              onTap: () => _showThemePicker(context, ref, l10n, isPremium),
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

  Future<void> _setPushOptIn(BuildContext context, WidgetRef ref, bool value) async {
    await ref.read(authRepositoryProvider).syncDeviceProfile(pushOptIn: value);
    await pushNotificationService.setPushOptIn(value);
    ref.invalidate(userProfileProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? AppLocalizations.of(context)!.pushNotificationsOn : AppLocalizations.of(context)!.pushNotificationsOff),
      ),
    );
  }

  Future<void> _editNickname(
    BuildContext context,
    WidgetRef ref,
    String? currentName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playerNickname),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: AppValidators.nicknameMaxLength,
            decoration: InputDecoration(
              hintText: l10n.playerNicknameHint,
              helperText: l10n.playerNicknameDesc,
            ),
            validator: (value) => AppValidators.nickname(
              value,
              emptyError: l10n.playerNicknameInvalid,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      final nickname = controller.text.trim();
      await ref.read(authRepositoryProvider).setDisplayName(
            nickname.isEmpty ? null : nickname,
          );
      ref.invalidate(userProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playerNicknameSaved)),
        );
      }
    } on SyncUserException catch (e) {
      if (!context.mounted) return;
      final message = e.errorCode == 'display_name_taken'
          ? l10n.playerNicknameTaken
          : l10n.playerNicknameInvalid;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      controller.dispose();
    }
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
        AppThemeMode.darkGold => l10n.themeDarkGold,
        AppThemeMode.lightClassic => l10n.themeLightClassic,
      };

  String _themeDescription(AppThemeMode mode, AppLocalizations l10n) => switch (mode) {
        AppThemeMode.system => l10n.themeSystemDesc,
        AppThemeMode.dark => l10n.themeDarkDesc,
        AppThemeMode.light => l10n.themeLightDesc,
        AppThemeMode.darkGold => l10n.themeDarkGoldDesc,
        AppThemeMode.lightClassic => l10n.themeLightClassicDesc,
      };

  void _showLocalePicker(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    _showGlassPicker(
      context: context,
      ref: ref,
      children: AppLocale.values.map((locale) {
        return _PickerTile(
          title: _localeLabel(locale, l10n),
          selected: ref.watch(localeProvider) == locale,
          onTap: () {
            ref.read(localeProvider.notifier).setLocale(locale);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isPremium,
  ) {
    final modes = AppThemeMode.values.where((m) => !m.isPremiumOnly || isPremium);
    _showGlassPicker(
      context: context,
      ref: ref,
      children: modes.map((mode) {
        return _PickerTile(
          icon: switch (mode) {
            AppThemeMode.system => Icons.brightness_auto_rounded,
            AppThemeMode.dark || AppThemeMode.darkGold => Icons.dark_mode_rounded,
            AppThemeMode.light || AppThemeMode.lightClassic => Icons.light_mode_rounded,
          },
          title: _themeLabel(mode, l10n),
          subtitle: _themeDescription(mode, l10n),
          selected: ref.watch(themeModeProvider) == mode,
          onTap: () {
            ref.read(themeModeProvider.notifier).setMode(mode, isPremium: isPremium);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showGlassPicker({
    required BuildContext context,
    required WidgetRef ref,
    required List<Widget> children,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: CrossBallGlassPanel(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    return ListTile(
      leading: icon != null ? Icon(icon, color: colors.lime) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: selected ? Icon(Icons.check_circle_rounded, color: colors.lime) : null,
      onTap: onTap,
    );
  }
}
