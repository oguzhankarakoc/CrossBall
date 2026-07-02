import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_ui.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.premium),
      body: PitchBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.workspace_premium, size: 72, color: colors.accent),
                const SizedBox(height: 24),
                Text(
                  l10n.premiumTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.premiumDesc,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const _PremiumFeature(icon: Icons.grid_4x4, text: '4×4 premium grids'),
                const _PremiumFeature(icon: Icons.all_inclusive, text: 'Unlimited practice'),
                const _PremiumFeature(icon: Icons.analytics_outlined, text: 'Advanced stats'),
                const _PremiumFeature(icon: Icons.palette_outlined, text: 'Exclusive themes'),
                const _PremiumFeature(icon: Icons.block, text: 'No ads'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('In-app purchase coming soon')),
                      );
                    },
                    child: Text(l10n.upgradePremium),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
