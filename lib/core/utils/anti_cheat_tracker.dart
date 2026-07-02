import 'dart:async';

import 'package:flutter/widgets.dart';

import '../constants/game_constants.dart';

/// Tracks session timing, background duration, and inactivity for anti-cheat.
class AntiCheatTracker with WidgetsBindingObserver {
  AntiCheatTracker({required this.gridSize, VoidCallback? onSuspicious})
      : _onSuspicious = onSuspicious {
    WidgetsBinding.instance.addObserver(this);
    _startedAt = DateTime.now();
    _lastInteractionAt = _startedAt;
    _startInactivityTimer();
  }

  final int gridSize;
  final VoidCallback? _onSuspicious;

  DateTime? _startedAt;
  DateTime? _backgroundStartedAt;
  DateTime? _lastInteractionAt;

  int _backgroundDurationMs = 0;
  int _inactivePeriods = 0;
  bool _isSuspicious = false;
  Timer? _inactivityTimer;

  bool get isSuspicious => _isSuspicious;

  int get backgroundDurationMs => _backgroundDurationMs;
  int get inactivePeriods => _inactivePeriods;

  int get totalDurationMs {
    if (_startedAt == null) return 0;
    return DateTime.now().difference(_startedAt!).inMilliseconds;
  }

  void recordInteraction() {
    _lastInteractionAt = DateTime.now();
  }

  void evaluate() {
    final threshold = gridSize == 3
        ? GameConstants.suspiciousDurationMs3x3
        : GameConstants.suspiciousDurationMs4x4;

    final duration = totalDurationMs;
    final bgRatio = duration > 0 ? _backgroundDurationMs / duration : 0;

    if (duration > threshold ||
        bgRatio > 0.5 ||
        _inactivePeriods >= GameConstants.maxInactivePeriods) {
      _isSuspicious = true;
      _onSuspicious?.call();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundStartedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed &&
        _backgroundStartedAt != null) {
      _backgroundDurationMs += DateTime.now()
          .difference(_backgroundStartedAt!)
          .inMilliseconds;
      _backgroundStartedAt = null;
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_lastInteractionAt == null) return;
      final inactive = DateTime.now()
          .difference(_lastInteractionAt!)
          .inMilliseconds;
      if (inactive >= GameConstants.inactivityThresholdMs) {
        _inactivePeriods++;
        _lastInteractionAt = DateTime.now();
      }
    });
  }

  Map<String, dynamic> toMetadata() => {
        'total_duration_ms': totalDurationMs,
        'background_duration_ms': _backgroundDurationMs,
        'inactive_periods': _inactivePeriods,
        'is_suspicious': _isSuspicious,
      };

  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
