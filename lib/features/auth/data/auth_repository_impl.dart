import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'auth_remote_data_source.dart';
import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';

const _keyUserUuid = 'crossball_user_uuid';
const _keyOnboardingComplete = 'crossball_onboarding_complete';
const _keyIsPremium = 'crossball_is_premium';

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
    final localPremium = prefs.getBool(_keyIsPremium) ?? false;

    final remote = await _remote.syncUser(
      userUuid: id,
      onboardingComplete: onboarding,
      isPremium: localPremium,
    );

    final isPremium = remote?['is_premium'] as bool? ?? localPremium;
    await prefs.setBool(_keyIsPremium, isPremium);

    return UserProfile(
      userUuid: id,
      onboardingComplete: onboarding,
      isPremium: isPremium,
    );
  }

  @override
  Future<void> setPremium(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyIsPremium, value);
    final id = await _secureStorage.read(key: _keyUserUuid);
    if (id != null) {
      await _remote.syncUser(userUuid: id, isPremium: value);
    }
  }

  @override
  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboardingComplete, value);
    final id = await _secureStorage.read(key: _keyUserUuid);
    if (id != null) {
      await _remote.syncUser(userUuid: id, onboardingComplete: value);
    }
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }
}
