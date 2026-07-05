import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/utils/daily_puzzle_schedule.dart';
import '../../../shared/providers/app_providers.dart';

enum DailyPuzzleRolloutPhase {
  ready,
  generating,
  failed,
  pending,
  unavailable,
}

class DailyPuzzleRolloutStatus {
  const DailyPuzzleRolloutStatus({
    required this.puzzleDate,
    required this.phase,
    this.startedAt,
    this.elapsedSeconds = 0,
    this.retryAfterSeconds = 30,
    this.errorMessage,
  });

  final String puzzleDate;
  final DailyPuzzleRolloutPhase phase;
  final DateTime? startedAt;
  final int elapsedSeconds;
  final int retryAfterSeconds;
  final String? errorMessage;

  bool get isReady => phase == DailyPuzzleRolloutPhase.ready;

  bool get isBlocked {
    if (phase == DailyPuzzleRolloutPhase.generating) return true;
    if (phase == DailyPuzzleRolloutPhase.pending &&
        DailyPuzzleSchedule.isWithinRolloutWindow()) {
      return true;
    }
    return false;
  }

  bool get isFailed => phase == DailyPuzzleRolloutPhase.failed;

  factory DailyPuzzleRolloutStatus.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'pending';
    return DailyPuzzleRolloutStatus(
      puzzleDate: json['puzzle_date'] as String? ??
          DailyPuzzleSchedule.todayPuzzleDateUtc(),
      phase: switch (status) {
        'ready' => DailyPuzzleRolloutPhase.ready,
        'generating' => DailyPuzzleRolloutPhase.generating,
        'failed' => DailyPuzzleRolloutPhase.failed,
        'unavailable' => DailyPuzzleRolloutPhase.unavailable,
        _ => DailyPuzzleRolloutPhase.pending,
      },
      startedAt: _parseDateTime(json['started_at']),
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      retryAfterSeconds: (json['retry_after'] as num?)?.toInt() ?? 30,
      errorMessage: json['error_message'] as String?,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

final dailyPuzzleRolloutProvider =
    AsyncNotifierProvider<DailyPuzzleRolloutNotifier, DailyPuzzleRolloutStatus>(
  DailyPuzzleRolloutNotifier.new,
);

class DailyPuzzleRolloutNotifier extends AsyncNotifier<DailyPuzzleRolloutStatus> {
  @override
  Future<DailyPuzzleRolloutStatus> build() async {
    return _fetchStatus();
  }

  Future<DailyPuzzleRolloutStatus> refresh() async {
    state = const AsyncLoading();
    final next = await _fetchStatus();
    state = AsyncData(next);
    return next;
  }

  Future<DailyPuzzleRolloutStatus> _fetchStatus() async {
    if (!AppConfig.isSupabaseConfigured) {
      return DailyPuzzleRolloutStatus(
        puzzleDate: DailyPuzzleSchedule.todayPuzzleDateUtc(),
        phase: DailyPuzzleRolloutPhase.ready,
      );
    }

    final repo = ref.read(puzzleRepositoryProvider);
    final raw = await repo.fetchDailyRolloutStatus();
    cbDebug('Daily', 'rollout status', raw);
    return DailyPuzzleRolloutStatus.fromJson(raw);
  }
}
