import 'user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> getOrCreateAnonymousUser();
  Future<String?> getUserUuid();
  Future<void> setOnboardingComplete(bool value);
  Future<void> setPremium(bool value);
  Future<bool> isOnboardingComplete();
  Future<UserProfile> setDisplayName(String? displayName);
  Future<void> syncDeviceProfile({bool? pushOptIn});
}
