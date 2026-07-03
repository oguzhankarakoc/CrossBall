import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../premium/premium_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track('premium_viewed');
    });
  }

  Future<void> _purchase() async {
    setState(() => _loading = true);
    try {
      final success = await ref.read(premiumServiceProvider).purchasePremium();
      if (success) {
        await ref.read(authRepositoryProvider).setPremium(true);
        ref.invalidate(userProfileProvider);
        ref.read(analyticsProvider).track('premium_conversion');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.premiumActivated)),
          );
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.premium),
      body: PitchBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(Icons.workspace_premium, size: 72, color: colors.accent),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.premiumTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.premiumDesc,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _PremiumFeature(icon: Icons.grid_4x4, text: l10n.premiumFeatureGrid),
                _PremiumFeature(icon: Icons.all_inclusive, text: l10n.premiumFeaturePractice),
                _PremiumFeature(icon: Icons.analytics_outlined, text: l10n.premiumFeatureStats),
                _PremiumFeature(icon: Icons.palette_outlined, text: l10n.premiumFeatureThemes),
                _PremiumFeature(icon: Icons.block, text: l10n.premiumFeatureNoAds),
                const Spacer(),
                if (isPremium)
                  Text(l10n.premiumActive, style: TextStyle(color: colors.accent))
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _purchase,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.upgradePremium),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(premiumServiceProvider).restorePurchases(),
                    child: Text(l10n.restorePurchases),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  const _PremiumFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
