import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../../features/premium/premium_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../ads_service.dart';

/// Fixed bottom banner slot — full-width adaptive banner above nav or below gameplay.
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
    return ColoredBox(
      color: colors.surface.withValues(alpha: 0.98),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.glassBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: BannerAdWidget(placement: placement),
          ),
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
  double _height = AdSize.banner.height.toDouble();
  bool _loaded = false;
  bool _loading = false;
  int? _lastWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAd(force: false);
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) {
      _disposeBanner();
      _syncAd(force: true);
    }
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
    _loading = false;
  }

  Future<void> _syncAd({required bool force}) async {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium || !AppConfig.isAdMobEnabled) {
      if (_banner != null && mounted) {
        setState(_disposeBanner);
      }
      return;
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (!force && (_loading || (_banner != null && _lastWidth == width))) {
      return;
    }

    _disposeBanner();
    _lastWidth = width;
    _loading = true;

    final ads = ref.read(adsServiceProvider);
    final banner = await ads.createAdaptiveBanner(
      placement: widget.placement,
      width: width,
    );

    if (!mounted) {
      banner?.dispose();
      return;
    }

    _loading = false;
    if (banner == null) {
      setState(() {
        _loaded = false;
        _height = AdSize.banner.height.toDouble();
      });
      return;
    }

    setState(() {
      _banner = banner;
      _loaded = true;
      _height = banner.size.height.toDouble();
    });

    ref.read(analyticsProvider).track('ad_impression', properties: {
      'placement': widget.placement.name,
      'format': 'banner',
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
        _syncAd(force: true);
      }
    });

    if (!_loaded || _banner == null) {
      return SizedBox(
        width: double.infinity,
        height: _height,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final width = _banner!.size.width.toDouble();
    final height = _banner!.size.height.toDouble();

    // Keep platform views strictly bounded — never use OverflowBox (iOS WKWebView bleed).
    return Center(
      child: ClipRRect(
        borderRadius: AppRadius.smBorder,
        child: SizedBox(
          width: width,
          height: height,
          child: AdWidget(ad: _banner!),
        ),
      ),
    );
  }
}
