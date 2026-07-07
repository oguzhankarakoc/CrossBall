import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_ui.dart';

class FootballFactBanner extends StatelessWidget {
  const FootballFactBanner({
    super.key,
    required this.text,
    this.compact = false,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? AppSpacing.sm : AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: EdgeInsets.zero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.xlBorder,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colors.lime.withValues(alpha: 0.14),
                colors.surfaceElevated.withValues(alpha: 0.35),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.xl),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.lime, colors.accent],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(compact ? AppSpacing.sm + 2 : AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.lime.withValues(alpha: 0.16),
                          borderRadius: AppRadius.lgBorder,
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: colors.lime,
                          size: compact ? 18 : 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.footballFactTitle,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colors.lime,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                            ),
                            SizedBox(height: compact ? 4 : AppSpacing.xs),
                            Text(
                              text,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.textPrimary.withValues(alpha: 0.92),
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
