import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../../features/premium/premium_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../ads_service.dart';

/// Fixed bottom banner slot — use on shell, gameplay, result and stats screens.
class CrossBallBannerSlot extends ConsumerWidget {
  const CrossBallBannerSlot({super.key, required this.placement});

  final AdPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium || !AppConfig.isAdMobEnabled) {
      return const SizedBox.shrink();
    }

    final colors = context.cb;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: colors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: BannerAdWidget(placement: placement),
        ),
      ),
    );
  }
}

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key, required this.placement});

  final AdPlacement placement;

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ads = ref.read(adsServiceProvider);
    _banner = ads.createBanner(widget.placement);
    _banner?.load().then((_) {
      if (mounted) {
        setState(() => _loaded = true);
        ref.read(analyticsProvider).track('ad_impression', properties: {
          'placement': widget.placement.name,
          'format': 'banner',
        });
      }
    });
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) {
      return const SizedBox(height: 50, width: double.infinity);
    }
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
