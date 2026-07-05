import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/device/device_timezone.dart';
import 'auth_remote_data_source.dart';
import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';

const _keyUserUuid = 'crossball_user_uuid';
const _keyOnboardingComplete = 'crossball_onboarding_complete';
const _keyDisplayName = 'crossball_display_name';
const _keyPushOptIn = 'crossball_push_opt_in';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
    AuthRemoteDataSource? remote,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefsOverride = prefs,
        _remote = remote ?? AuthRemoteDataSource();

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _prefsOverride;
  final AuthRemoteDataSource _remote;
  final _uuid = const Uuid();

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  @override
  Future<String?> getUserUuid() => _secureStorage.read(key: _keyUserUuid);

  @override
  Future<UserProfile> getOrCreateAnonymousUser() async {
    var id = await _secureStorage.read(key: _keyUserUuid);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await _secureStorage.write(key: _keyUserUuid, value: id);
    }
    final onboarding = await isOnboardingComplete();
    final prefs = await _prefs;
    final localDisplayName = prefs.getString(_keyDisplayName);
    final localPushOptIn = prefs.getBool(_keyPushOptIn) ?? true;

    Map<String, dynamic>? remote;
    try {
      remote = await _remote.syncUser(
        userUuid: id,
        onboardingComplete: onboarding,
        displayName: localDisplayName,
        timezoneOffsetMinutes: DeviceTimezone.offsetMinutes,
        pushOptIn: localPushOptIn,
      );
    } on SyncUserException catch (e) {
      cbDebug('Auth', 'syncUser remote failed — using local profile', {
        'error': e.errorCode,
        'status': e.statusCode,
      });
      remote = null;
    }

    final isPremium = AppConfig.forceFreeTier
        ? false
        : (remote?['is_premium'] as bool? ?? false);

    final displayName = remote?['display_name'] as String? ?? localDisplayName;
    final pushOptIn = remote?['push_opt_in'] as bool? ?? localPushOptIn;

    if (displayName != null && displayName.isNotEmpty) {
      await prefs.setString(_keyDisplayName, displayName);
    } else {
      await prefs.remove(_keyDisplayName);
    }
    await prefs.setBool(_keyPushOptIn, pushOptIn);

    return UserProfile(
      userUuid: id,
      displayName: displayName,
      onboardingComplete: onboarding,
      isPremium: isPremium,
      pushOptIn: pushOptIn,
    );
  }

  @override
  Future<void> setPremium(bool value) async {
    // Premium is server-authoritative via verify-premium; local-only no-op.
    if (AppConfig.forceFreeTier) return;
  }

  @override
  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboardingComplete, value);
    final id = await _secureStorage.read(key: _keyUserUuid);
    if (id != null) {
      try {
        await _remote.syncUser(userUuid: id, onboardingComplete: value);
      } on SyncUserException {
        // Local flag remains; will sync on next launch.
      }
    }
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  @override
  Future<UserProfile> setDisplayName(String? displayName) async {
    final id = await _secureStorage.read(key: _keyUserUuid);
    if (id == null) throw SyncUserException('missing_user_uuid', 0);

    final trimmed = displayName?.trim();
    final remote = await _remote.syncUser(
      userUuid: id,
      displayName: trimmed,
      clearDisplayName: trimmed == null || trimmed.isEmpty,
    );

    final prefs = await _prefs;
    final resolved = remote['display_name'] as String?;
    if (resolved != null && resolved.isNotEmpty) {
      await prefs.setString(_keyDisplayName, resolved);
    } else {
      await prefs.remove(_keyDisplayName);
    }

    final profile = await getOrCreateAnonymousUser();
    return profile.copyWith(displayName: resolved);
  }

  @override
  Future<void> syncDeviceProfile({bool? pushOptIn}) async {
    final id = await _secureStorage.read(key: _keyUserUuid);
    if (id == null) return;

    final prefs = await _prefs;
    final optIn = pushOptIn ?? prefs.getBool(_keyPushOptIn) ?? true;

    try {
      await _remote.syncUser(
        userUuid: id,
        timezoneOffsetMinutes: DeviceTimezone.offsetMinutes,
        pushOptIn: optIn,
      );
    } on SyncUserException {
      // Best-effort device profile sync.
    }
    await prefs.setBool(_keyPushOptIn, optIn);
  }
}
