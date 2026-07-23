import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../widgets/crossball_ui.dart';
import 'crossball_tip_sheet.dart';
import 'feature_info_topic.dart';

class FeatureInfoCopy {
  const FeatureInfoCopy({
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  final String title;
  final String subtitle;
  final List<({IconData icon, String title, String body})> steps;
}

FeatureInfoCopy featureInfoCopyFor(
  AppLocalizations l10n,
  FeatureInfoTopic topic,
) {
  return switch (topic) {
    FeatureInfoTopic.home => FeatureInfoCopy(
        title: l10n.featureInfoHomeTitle,
        subtitle: l10n.featureInfoHomeSubtitle,
        steps: [
          (
            icon: Icons.today_rounded,
            title: l10n.featureInfoHomeStep1Title,
            body: l10n.featureInfoHomeStep1Body,
          ),
          (
            icon: Icons.fitness_center_rounded,
            title: l10n.featureInfoHomeStep2Title,
            body: l10n.featureInfoHomeStep2Body,
          ),
          (
            icon: Icons.local_fire_department_rounded,
            title: l10n.featureInfoHomeStep3Title,
            body: l10n.featureInfoHomeStep3Body,
          ),
        ],
      ),
    FeatureInfoTopic.practiceHub => FeatureInfoCopy(
        title: l10n.featureInfoPracticeHubTitle,
        subtitle: l10n.featureInfoPracticeHubSubtitle,
        steps: [
          (
            icon: Icons.grid_view_rounded,
            title: l10n.featureInfoPracticeHubStep1Title,
            body: l10n.featureInfoPracticeHubStep1Body,
          ),
          (
            icon: Icons.flash_on_rounded,
            title: l10n.featureInfoPracticeHubStep2Title,
            body: l10n.featureInfoPracticeHubStep2Body,
          ),
          (
            icon: Icons.swipe_rounded,
            title: l10n.featureInfoPracticeHubStep3Title,
            body: l10n.featureInfoPracticeHubStep3Body,
          ),
        ],
      ),
    FeatureInfoTopic.daily => FeatureInfoCopy(
        title: l10n.featureInfoDailyTitle,
        subtitle: l10n.featureInfoDailySubtitle,
        steps: [
          (
            icon: Icons.touch_app_rounded,
            title: l10n.featureInfoDailyStep1Title,
            body: l10n.featureInfoDailyStep1Body,
          ),
          (
            icon: Icons.sports_soccer_rounded,
            title: l10n.featureInfoDailyStep2Title,
            body: l10n.featureInfoDailyStep2Body,
          ),
          (
            icon: Icons.auto_awesome_rounded,
            title: l10n.featureInfoDailyStep3Title,
            body: l10n.featureInfoDailyStep3Body,
          ),
        ],
      ),
    FeatureInfoTopic.classicPractice => FeatureInfoCopy(
        title: l10n.featureInfoClassicTitle,
        subtitle: l10n.featureInfoClassicSubtitle,
        steps: [
          (
            icon: Icons.search_rounded,
            title: l10n.featureInfoClassicStep1Title,
            body: l10n.featureInfoClassicStep1Body,
          ),
          (
            icon: Icons.all_inclusive_rounded,
            title: l10n.featureInfoClassicStep2Title,
            body: l10n.featureInfoClassicStep2Body,
          ),
          (
            icon: Icons.ondemand_video_rounded,
            title: l10n.featureInfoClassicStep3Title,
            body: l10n.featureInfoClassicStep3Body,
          ),
        ],
      ),
    FeatureInfoTopic.quickGrid => FeatureInfoCopy(
        title: l10n.featureInfoQuickGridTitle,
        subtitle: l10n.featureInfoQuickGridSubtitle,
        steps: [
          (
            icon: Icons.looks_5_rounded,
            title: l10n.featureInfoQuickGridStep1Title,
            body: l10n.featureInfoQuickGridStep1Body,
          ),
          (
            icon: Icons.timer_rounded,
            title: l10n.featureInfoQuickGridStep2Title,
            body: l10n.featureInfoQuickGridStep2Body,
          ),
          (
            icon: Icons.speed_rounded,
            title: l10n.featureInfoQuickGridStep3Title,
            body: l10n.featureInfoQuickGridStep3Body,
          ),
        ],
      ),
    FeatureInfoTopic.matchGrid => FeatureInfoCopy(
        title: l10n.featureInfoMatchGridTitle,
        subtitle: l10n.featureInfoMatchGridSubtitle,
        steps: [
          (
            icon: Icons.touch_app_rounded,
            title: l10n.featureInfoMatchGridStep1Title,
            body: l10n.featureInfoMatchGridStep1Body,
          ),
          (
            icon: Icons.grid_on_rounded,
            title: l10n.featureInfoMatchGridStep2Title,
            body: l10n.featureInfoMatchGridStep2Body,
          ),
          (
            icon: Icons.check_circle_outline_rounded,
            title: l10n.featureInfoMatchGridStep3Title,
            body: l10n.featureInfoMatchGridStep3Body,
          ),
        ],
      ),
    FeatureInfoTopic.timeline => FeatureInfoCopy(
        title: l10n.featureInfoTimelineTitle,
        subtitle: l10n.featureInfoTimelineSubtitle,
        steps: [
          (
            icon: Icons.timeline_rounded,
            title: l10n.featureInfoTimelineStep1Title,
            body: l10n.featureInfoTimelineStep1Body,
          ),
          (
            icon: Icons.history_edu_rounded,
            title: l10n.featureInfoTimelineStep2Title,
            body: l10n.featureInfoTimelineStep2Body,
          ),
        ],
      ),
  };
}

Future<void> showFeatureInfoSheet(
  BuildContext context,
  FeatureInfoTopic topic,
) {
  return showCrossBallTipSheet<void>(
    context: context,
    builder: (context) => _FeatureInfoSheet(topic: topic),
  );
}

/// Opens the sheet and marks the topic seen (for manual info taps).
Future<void> openFeatureInfo(
  BuildContext context,
  WidgetRef ref,
  FeatureInfoTopic topic,
) async {
  ref.read(analyticsProvider).track(
    'feature_info_opened',
    properties: {'topic': topic.analyticsName, 'source': 'button'},
  );
  await showFeatureInfoSheet(context, topic);
  await ref.read(featureInfoStoreProvider).markSeen(topic);
}

/// Shows once on first visit to a screen/mode.
Future<void> maybeAutoShowFeatureInfo(
  BuildContext context,
  WidgetRef ref,
  FeatureInfoTopic topic,
) async {
  final store = ref.read(featureInfoStoreProvider);
  if (await store.hasSeen(topic)) return;
  if (!context.mounted) return;
  ref.read(analyticsProvider).track(
    'feature_info_opened',
    properties: {'topic': topic.analyticsName, 'source': 'auto'},
  );
  await showFeatureInfoSheet(context, topic);
  await store.markSeen(topic);
}

/// Invisible host that auto-presents help once after the first frame.
class FeatureInfoAutoPresenter extends ConsumerStatefulWidget {
  const FeatureInfoAutoPresenter({
    super.key,
    required this.topic,
    this.delay = const Duration(milliseconds: 500),
  });

  final FeatureInfoTopic topic;
  final Duration delay;

  @override
  ConsumerState<FeatureInfoAutoPresenter> createState() =>
      _FeatureInfoAutoPresenterState();
}

class _FeatureInfoAutoPresenterState
    extends ConsumerState<FeatureInfoAutoPresenter> {
  var _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void didUpdateWidget(covariant FeatureInfoAutoPresenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic) {
      _scheduled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
    }
  }

  Future<void> _maybeShow() async {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    await Future<void>.delayed(widget.delay);
    if (!mounted) return;
    await maybeAutoShowFeatureInfo(context, ref, widget.topic);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class FeatureInfoIconButton extends ConsumerWidget {
  const FeatureInfoIconButton({super.key, required this.topic});

  final FeatureInfoTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    return IconButton(
      tooltip: l10n.featureInfoTooltip,
      icon: Icon(Icons.info_outline_rounded, color: colors.accent),
      onPressed: () => openFeatureInfo(context, ref, topic),
    );
  }
}

class _FeatureInfoSheet extends StatelessWidget {
  const _FeatureInfoSheet({required this.topic});

  final FeatureInfoTopic topic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = featureInfoCopyFor(l10n, topic);

    return CrossBallTipCard(
      eyebrow: l10n.tipSheetEyebrow,
      title: copy.title,
      subtitle: copy.subtitle,
      steps: copy.steps,
      ctaLabel: l10n.featureInfoGotIt,
      onCta: () => Navigator.of(context).pop(),
    );
  }
}
