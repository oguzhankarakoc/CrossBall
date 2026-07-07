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
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAd());
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAd();
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
  }

  void _syncAd() {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium || !AppConfig.isAdMobEnabled) {
      if (_banner != null) {
        setState(_disposeBanner);
      }
      return;
    }

    if (_banner != null) return;

    final ads = ref.read(adsServiceProvider);
    final banner = ads.createBanner(widget.placement);
    if (banner == null) return;

    _banner = banner;
    banner.load().then((_) {
      if (!mounted || _banner != banner) {
        banner.dispose();
        return;
      }
      setState(() => _loaded = true);
      ref.read(analyticsProvider).track('ad_impression', properties: {
        'placement': widget.placement.name,
        'format': 'banner',
      });
    });
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isPremiumProvider, (previous, next) {
      if (previous == next) return;
      if (next) {
        setState(_disposeBanner);
      } else {
        _syncAd();
      }
    });

    if (!_loaded || _banner == null) {
      return const SizedBox.shrink();
    }

    final width = _banner!.size.width.toDouble();
    final height = _banner!.size.height.toDouble();

    // iOS WKWebView can paint outside bounds and cover the puzzle — hard clip.
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: OverflowBox(
          maxWidth: width,
          maxHeight: height,
          alignment: Alignment.center,
          child: AdWidget(ad: _banner!),
        ),
      ),
    );
  }
}
