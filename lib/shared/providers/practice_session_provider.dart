import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../core/debug/crossball_debug_log.dart';
import '../../core/debug/practice_debug_log.dart';
import '../../core/network/network_providers.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/practice/data/practice_quota_api.dart';

/// Server-synced daily practice quota with rewarded-ad unlock for free users.
class PracticeSessionState {
  const PracticeSessionState({
    required this.dateKey,
    required this.completedToday,
    required this.dailyLimit,
    required this.isPremium,
    this.adUnlockGranted = false,
    this.isSyncing = false,
    this.syncError,
  });

  final String dateKey;
  final int completedToday;
  final int dailyLimit;
  final bool isPremium;
  final bool adUnlockGranted;
  final bool isSyncing;
  final String? syncError;

  int get remaining => (dailyLimit - completedToday).clamp(0, dailyLimit);

  bool get hasReachedLimit => completedToday >= dailyLimit;

  /// Free users need a rewarded ad before every new training session.
  bool get needsRewardedAdForNextSession => !isPremium && !adUnlockGranted;

  bool get canStartSession =>
      !hasReachedLimit && (!needsRewardedAdForNextSession || adUnlockGranted);

  PracticeSessionState copyWith({
    String? dateKey,
    int? completedToday,
    int? dailyLimit,
    bool? isPremium,
    bool? adUnlockGranted,
    bool? isSyncing,
    String? syncError,
    bool clearSyncError = false,
  }) =>
      PracticeSessionState(
        dateKey: dateKey ?? this.dateKey,
        completedToday: completedToday ?? this.completedToday,
        dailyLimit: dailyLimit ?? this.dailyLimit,
        isPremium: isPremium ?? this.isPremium,
        adUnlockGranted: adUnlockGranted ?? this.adUnlockGranted,
        isSyncing: isSyncing ?? this.isSyncing,
        syncError: clearSyncError ? null : (syncError ?? this.syncError),
      );

  factory PracticeSessionState.fromQuotaJson(Map<String, dynamic> json) {
    return PracticeSessionState(
      dateKey: json['usage_date'] as String? ?? '',
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? GameConstants.freePracticeDailyLimit,
      isPremium: json['is_premium'] as bool? ?? false,
      adUnlockGranted: json['ad_unlock_granted'] as bool? ?? false,
    );
  }

  static const initial = PracticeSessionState(
    dateKey: '',
    completedToday: 0,
    dailyLimit: GameConstants.freePracticeDailyLimit,
    isPremium: false,
  );
}

final practiceQuotaApiProvider = Provider<PracticeQuotaApi>(
  (ref) => PracticeQuotaApi(httpClient: ref.watch(apiHttpClientProvider)),
);

final practiceSessionProvider =
    StateNotifierProvider<PracticeSessionNotifier, PracticeSessionState>(
  (ref) => PracticeSessionNotifier(ref),
);

class PracticeSessionNotifier extends StateNotifier<PracticeSessionState> {
  PracticeSessionNotifier(this._ref) : super(PracticeSessionState.initial);

  final Ref _ref;
  DateTime? _lastSyncAt;
  String? _lastSyncUserUuid;

  /// Skip network if we synced this user within the last [ttl].
  static const _syncTtl = Duration(seconds: 45);

  PracticeQuotaApi get _api => _ref.read(practiceQuotaApiProvider);

  Future<void> syncFromServer(String userUuid, {bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastSyncUserUuid == userUuid &&
        _lastSyncAt != null &&
        now.difference(_lastSyncAt!) < _syncTtl &&
        state.syncError == null &&
        state.dateKey.isNotEmpty) {
      practiceDebug('syncQuota skipped (fresh)', {
        'ageMs': now.difference(_lastSyncAt!).inMilliseconds,
        'completedToday': state.completedToday,
      });
      return;
    }
    cbDebug('Practice', 'syncQuota start', {'userUuid': userUuid});
    state = state.copyWith(isSyncing: true, clearSyncError: true);
    try {
      final quota = await _api.fetchQuota(userUuid);
      state = PracticeSessionState.fromQuotaJson(quota);
      _lastSyncAt = DateTime.now();
      _lastSyncUserUuid = userUuid;
      cbDebug('Practice', 'syncQuota OK', {
        'completedToday': state.completedToday,
        'dailyLimit': state.dailyLimit,
        'isPremium': state.isPremium,
      });
    } catch (e, st) {
      cbDebugError('Practice', 'syncQuota failed', e, st);
      state = state.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      );
    }
  }

  Future<void> grantAdUnlock(String userUuid) async {
    final quota = await _api.grantAdUnlock(userUuid);
    state = PracticeSessionState.fromQuotaJson(quota);
    _lastSyncAt = DateTime.now();
    _lastSyncUserUuid = userUuid;
  }

  /// Optimistic bump until [complete-session] flushes; reconciled on next sync.
  Future<void> onPracticeSessionCompleted(String userUuid) async {
    state = state.copyWith(
      completedToday: state.completedToday + 1,
      adUnlockGranted: false,
    );
    await syncFromServer(userUuid, force: true);
  }

  Future<void> syncForCurrentUser() async {
    final profile = await _ref.read(userProfileProvider.future);
    await syncFromServer(profile.userUuid);
  }
}
