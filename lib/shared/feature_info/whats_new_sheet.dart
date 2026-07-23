import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_build_info.dart';
import '../../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import 'crossball_tip_sheet.dart';
import 'feature_info_topic.dart';

Future<void> showWhatsNewSheet(BuildContext context) {
  return showCrossBallTipSheet<void>(
    context: context,
    builder: (context) => const _WhatsNewSheet(),
  );
}

/// Shows once after install or app update, when the main shell is ready.
class WhatsNewAutoPresenter extends ConsumerStatefulWidget {
  const WhatsNewAutoPresenter({super.key});

  @override
  ConsumerState<WhatsNewAutoPresenter> createState() =>
      _WhatsNewAutoPresenterState();
}

class _WhatsNewAutoPresenterState extends ConsumerState<WhatsNewAutoPresenter> {
  var _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_scheduled || !mounted) return;
    _scheduled = true;

    final store = ref.read(whatsNewStoreProvider);
    if (!await store.shouldShowForCurrentBuild()) return;

    // Let Home paint first (and finish onboarding navigation).
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final isFirstOpen = await store.lastSeenVersionKey() == null;
    if (!mounted) return;

    ref.read(analyticsProvider).track(
      'whats_new_shown',
      properties: {
        'version': AppBuildInfo.versionKey,
        'first_open': isFirstOpen,
      },
    );

    if (!mounted) return;
    await showWhatsNewSheet(context);
    if (!mounted) return;

    await store.markCurrentBuildSeen();
    // Avoid stacking Home / Practice hub tips right after this sheet.
    final info = ref.read(featureInfoStoreProvider);
    await info.markSeen(FeatureInfoTopic.home);
    await info.markSeen(FeatureInfoTopic.practiceHub);

    ref.read(analyticsProvider).track(
      'whats_new_dismissed',
      properties: {'version': AppBuildInfo.versionKey},
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _WhatsNewSheet extends StatelessWidget {
  const _WhatsNewSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final steps = <({IconData icon, String title, String body})>[
      (
        icon: Icons.swipe_rounded,
        title: l10n.whatsNewStep1Title,
        body: l10n.whatsNewStep1Body,
      ),
      (
        icon: Icons.ondemand_video_rounded,
        title: l10n.whatsNewStep2Title,
        body: l10n.whatsNewStep2Body,
      ),
      (
        icon: Icons.info_outline_rounded,
        title: l10n.whatsNewStep3Title,
        body: l10n.whatsNewStep3Body,
      ),
    ];

    return CrossBallTipCard(
      eyebrow: l10n.whatsNewEyebrow,
      title: l10n.whatsNewTitle,
      subtitle: l10n.whatsNewSubtitle(AppBuildInfo.versionName),
      steps: steps,
      ctaLabel: l10n.whatsNewGotIt,
      onCta: () => Navigator.of(context).pop(),
    );
  }
}
