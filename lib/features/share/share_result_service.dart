import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/share_helper.dart';

import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/crossball_ui.dart';

/// Captures a branded result card and opens the native share sheet.
class ShareResultService {
  ShareResultService._();

  static Future<void> shareDailyResult({
    required BuildContext context,
    required GlobalKey cardKey,
    required double score,
    required int streak,
    String? challengeUrl,
    GlobalKey? anchorKey,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final text = StringBuffer()
      ..writeln('CrossBall — ${l10n.dailyChallenge}')
      ..writeln('${l10n.score}: ${score.toStringAsFixed(0)}');
    if (streak > 0) {
      text.writeln('${l10n.currentStreak}: $streak 🔥');
    }
    text.writeln(l10n.tagline);
    if (challengeUrl != null) text.writeln(challengeUrl);

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = await _writeTempPng(byteData.buffer.asUint8List());
          await ShareHelper.share(
            ShareParams(
              text: text.toString(),
              files: [XFile(file.path)],
            ),
            context: context,
            anchorKey: anchorKey ?? cardKey,
          );
          return;
        }
      }
    } catch (_) {}

    await ShareHelper.share(
      ShareParams(text: text.toString()),
      context: context,
      anchorKey: anchorKey,
    );
  }

  static Future<File> _writeTempPng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/crossball_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

/// Branded share card widget — wrap with [RepaintBoundary] + [GlobalKey].
class DailyShareCard extends StatelessWidget {
  const DailyShareCard({
    super.key,
    required this.score,
    required this.mistakes,
    required this.hintsUsed,
    required this.streak,
  });

  final double score;
  final int mistakes;
  final int hintsUsed;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.primary.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: AppRadius.xlBorder,
        border: Border.all(color: colors.lime.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CrossBallLogo(size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.puzzleComplete,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            score.toStringAsFixed(0),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: colors.lime,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(label: l10n.mistakes, value: '$mistakes'),
              _MiniStat(label: l10n.hintsUsed, value: '$hintsUsed'),
              if (streak > 0) _MiniStat(label: l10n.currentStreak, value: '$streak'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tagline,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
