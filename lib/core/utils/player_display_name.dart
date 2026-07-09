/// Player-facing nickname rules (matches settings: 3–20 chars when set).
const int kPlayerDisplayNameMaxLength = 20;
const String kAnonymousPlayerPrefix = 'Player';

/// Resolves the label shown in leaderboards, activity feed, and settings.
///
/// Prefers the chosen nickname; otherwise falls back to `Player #XXXX` from UUID.
String resolvePlayerDisplayLabel({
  String? displayName,
  String? userUuid,
}) {
  final nickname = displayName?.trim();
  if (nickname != null &&
      nickname.isNotEmpty &&
      nickname != kAnonymousPlayerPrefix) {
    if (nickname.length <= kPlayerDisplayNameMaxLength) return nickname;
    return nickname.substring(0, kPlayerDisplayNameMaxLength);
  }

  if (userUuid != null && userUuid.length >= 4) {
    final compact = userUuid.replaceAll('-', '');
    final suffix = compact.length >= 4
        ? compact.substring(0, 4).toUpperCase()
        : compact.toUpperCase();
    return '$kAnonymousPlayerPrefix #$suffix';
  }

  return kAnonymousPlayerPrefix;
}

String playerAvatarInitial(String displayLabel) {
  final trimmed = displayLabel.trim();
  if (trimmed.isEmpty) return '?';
  if (trimmed.startsWith('$kAnonymousPlayerPrefix #')) {
    return kAnonymousPlayerPrefix[0].toUpperCase();
  }
  return trimmed[0].toUpperCase();
}

bool isResolvedAnonymousLabel(String displayLabel) {
  return displayLabel.startsWith('$kAnonymousPlayerPrefix #') ||
      displayLabel == kAnonymousPlayerPrefix;
}
