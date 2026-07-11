import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Counts down from [duration] anchored at [startedAt]. Calls [onExpired] once.
class PuzzleCountdownTimer extends StatefulWidget {
  const PuzzleCountdownTimer({
    super.key,
    required this.startedAt,
    required this.duration,
    this.onExpired,
  });

  final DateTime startedAt;
  final Duration duration;
  final VoidCallback? onExpired;

  @override
  State<PuzzleCountdownTimer> createState() => _PuzzleCountdownTimerState();
}

class _PuzzleCountdownTimerState extends State<PuzzleCountdownTimer> {
  late Timer _timer;
  late Duration _remaining;
  bool _expiredNotified = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final left = widget.duration - elapsed;
    if (!mounted) return;
    setState(() {
      _remaining = left.isNegative ? Duration.zero : left;
    });
    if (_remaining == Duration.zero && !_expiredNotified) {
      _expiredNotified = true;
      widget.onExpired?.call();
    }
  }

  @override
  void didUpdateWidget(covariant PuzzleCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      _expiredNotified = false;
      _tick();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final totalSeconds = _remaining.inSeconds;
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    final urgent = totalSeconds <= 15;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 16,
          color: urgent ? colors.error : colors.lime,
        ),
        const SizedBox(width: 4),
        Text(
          '$m:$s',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: urgent ? colors.error : null,
              ),
        ),
      ],
    );
  }
}
