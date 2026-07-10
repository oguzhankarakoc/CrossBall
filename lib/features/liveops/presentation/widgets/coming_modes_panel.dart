import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';

/// Read-only teaser for upcoming modes (World XI, Themed Week, Blitz).
class ComingModesPanel extends StatelessWidget {
  const ComingModesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return CrossBallGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.comingModesTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.8),
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(color: colors.glassBorder),
                ),
                child: Text(
                  l10n.eventLockedBadge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.comingModesSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ComingModeRow(
            icon: Icons.public_rounded,
            title: l10n.modeWorldXiTitle,
            body: l10n.modeWorldXiBody,
          ),
          _ComingModeRow(
            icon: Icons.calendar_month_rounded,
            title: l10n.modeThemedWeekTitle,
            body: l10n.modeThemedWeekBody,
          ),
          _ComingModeRow(
            icon: Icons.bolt_rounded,
            title: l10n.modeBlitzTitle,
            body: l10n.modeBlitzBody,
            isLast: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => showComingModesSheet(context),
              child: Text(l10n.comingModesLearnMore),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingModeRow extends StatelessWidget {
  const _ComingModeRow({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showComingModesSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final colors = context.cb;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: colors.surface,
    builder: (ctx) {
      final sheetL10n = AppLocalizations.of(ctx)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetL10n.moreGameModes,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sheetL10n.comingModesSubtitle,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SheetModeTile(
                icon: Icons.public_rounded,
                title: sheetL10n.modeWorldXiTitle,
                body: sheetL10n.modeWorldXiBody,
                badge: sheetL10n.eventLockedBadge,
              ),
              _SheetModeTile(
                icon: Icons.calendar_month_rounded,
                title: sheetL10n.modeThemedWeekTitle,
                body: sheetL10n.modeThemedWeekBody,
                badge: sheetL10n.eventLockedBadge,
              ),
              _SheetModeTile(
                icon: Icons.bolt_rounded,
                title: sheetL10n.modeBlitzTitle,
                body: sheetL10n.modeBlitzBody,
                badge: sheetL10n.eventLockedBadge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.eventLockedMessage,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetModeTile extends StatelessWidget {
  const _SheetModeTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String body;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Text(
                      badge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
