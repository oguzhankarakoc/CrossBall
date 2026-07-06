import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../auth/data/auth_remote_data_source.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../premium/premium_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _loading = false;
  String? _priceLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track('premium_viewed');
      _loadStorePrice();
    });
  }

  Future<void> _loadStorePrice() async {
    if (!AppConfig.isIapEnabled) return;
    final product =
        await ref.read(premiumServiceProvider).fetchPremiumProduct();
    if (!mounted || product == null) return;
    setState(() => _priceLabel = product.price);
  }

  Future<void> _purchase() async {
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final profile = await ref.read(userProfileProvider.future);
      final success = await ref.read(premiumServiceProvider).purchasePremium(profile.userUuid);
      if (!mounted) return;
      if (success) {
        ref.invalidate(userProfileProvider);
        ref.read(analyticsProvider).track('premium_conversion');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.premiumActivated)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppConfig.isIapEnabled
                  ? l10n.premiumPurchaseUnavailable
                  : l10n.premiumDevNotConfigured,
            ),
          ),
        );
      }
    } on SyncUserException catch (e) {
      if (!mounted) return;
      final message = switch (e.errorCode) {
        'verification_failed' => l10n.premiumVerificationFailed,
        'invalid_product' => l10n.premiumPurchaseUnavailable,
        _ => l10n.premiumPurchaseFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'storekit_duplicate_product_object'
          ? l10n.premiumPurchasePending
          : l10n.premiumPurchaseFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
          child: SingleChildScrollView(
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
                _PremiumFeature(icon: Icons.all_inclusive, text: l10n.premiumFeaturePractice),
                _PremiumFeature(icon: Icons.analytics_outlined, text: l10n.premiumFeatureStats),
                _PremiumFeature(icon: Icons.palette_outlined, text: l10n.premiumFeatureThemes),
                _PremiumFeature(icon: Icons.block, text: l10n.premiumFeatureNoAds),
                const SizedBox(height: AppSpacing.xxl),
                if (isPremium)
                  Text(l10n.premiumActive, style: TextStyle(color: colors.accent))
                else ...[
                  if (_priceLabel != null) ...[
                    Text(
                      _priceLabel!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
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
                    onPressed: () async {
                      final profile = await ref.read(userProfileProvider.future);
                      await ref.read(premiumServiceProvider).restorePurchases(profile.userUuid);
                      ref.invalidate(userProfileProvider);
                    },
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
