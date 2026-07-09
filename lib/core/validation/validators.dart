/// Centralized input validation — no duplicated regex across screens.
abstract final class AppValidators {
  static final RegExp nicknamePattern =
      RegExp(r'^[\p{L}\p{N}._-]{3,20}$', unicode: true);

  static const int nicknameMinLength = 3;
  static const int nicknameMaxLength = 20;

  static String? nickname(String? value, {required String emptyError}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length < nicknameMinLength || trimmed.length > nicknameMaxLength) {
      return emptyError;
    }
    if (!nicknamePattern.hasMatch(trimmed)) return emptyError;
    return null;
  }

  static String? required(String? value, {required String message}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? minLength(
    String? value, {
    required int min,
    required String message,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length < min) return message;
    return null;
  }

  static String? searchQuery(String? value, {int minLength = 2}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length < minLength) return null;
    return null;
  }

  static String? friendCode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length < 6) return null;
    return null;
  }
}
