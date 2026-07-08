import 'string_normalizer.dart';

const _surnameParticles = {
  'de',
  'da',
  'do',
  'dos',
  'das',
  'van',
  'von',
  'der',
  'di',
  'del',
  'la',
  'le',
  'mc',
  'mac',
};

String _prepareNameForIdentity(String name) =>
    name.replaceAll(RegExp(r'\.(?=\S)'), '. ');

List<String> _normalizedNameParts(String name) {
  final normalized = StringNormalizer.normalize(_prepareNameForIdentity(name))
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .trim();
  return normalized.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
}

/// Client-side dedup key aligned with [data_pipeline/pipeline/player_identity.py].
String playerIdentityKey(String name) {
  final parts = _normalizedNameParts(name);
  if (parts.isEmpty) return '';
  final surname = _significantSurname(parts);
  if (parts.length == 1) return surname;
  final first = parts.first.replaceAll('.', '');
  final token = first.isEmpty ? '' : first[0];
  return '$surname|$token';
}

/// All name-token keys for a player — merges "Cristiano Ronaldo" with full legal names.
List<String> playerIdentityKeys(String name, {String? dbIdentityKey}) {
  final keys = <String>{};
  if (dbIdentityKey != null && dbIdentityKey.isNotEmpty) {
    keys.add(dbIdentityKey);
  }
  final parts = _normalizedNameParts(name);
  if (parts.isEmpty) return keys.toList();
  final first = parts.first.replaceAll('.', '');
  final token = first.isEmpty ? '' : first[0];
  for (final part in parts) {
    if (_surnameParticles.contains(part)) continue;
    keys.add('$part|$token');
  }
  return keys.toList();
}

/// Union-find dedupe: players sharing any identity key are merged into one entry.
List<T> dedupeByPlayerIdentity<T>({
  required List<T> items,
  required String Function(T item) nameOf,
  String? Function(T item)? identityKeyOf,
  required T Function(T primary, T secondary) merge,
  required int Function(T item) completenessScore,
}) {
  if (items.length <= 1) return items;

  final parent = List<int>.generate(items.length, (i) => i);

  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  void union(int a, int b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA != rootB) parent[rootB] = rootA;
  }

  final keyToIndex = <String, int>{};
  for (var i = 0; i < items.length; i++) {
    final keys = playerIdentityKeys(
      nameOf(items[i]),
      dbIdentityKey: identityKeyOf?.call(items[i]),
    );
    for (final key in keys) {
      final existing = keyToIndex[key];
      if (existing == null) {
        keyToIndex[key] = i;
      } else {
        union(i, existing);
      }
    }
  }

  final groups = <int, List<T>>{};
  for (var i = 0; i < items.length; i++) {
    groups.putIfAbsent(find(i), () => []).add(items[i]);
  }

  return groups.values.map((group) {
    group.sort((a, b) => completenessScore(b).compareTo(completenessScore(a)));
    return group.skip(1).fold(group.first, merge);
  }).toList();
}

String _significantSurname(List<String> parts) {
  for (var i = parts.length - 1; i >= 0; i--) {
    if (!_surnameParticles.contains(parts[i])) return parts[i];
  }
  return parts.last;
}

int playerCompletenessScore({
  required String name,
  String? nationalityCode,
  String? primaryPosition,
  int clubsCount = 0,
}) {
  var score = clubsCount * 5;
  if (nationalityCode != null && nationalityCode.isNotEmpty) score += 20;
  if (primaryPosition != null && primaryPosition.isNotEmpty) score += 10;
  score += name.length;
  if (!RegExp(r'^[A-Z]\.\s').hasMatch(name)) score += 15;
  return score;
}
