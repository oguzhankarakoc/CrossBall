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

/// Client-side dedup key aligned with [data_pipeline/pipeline/player_identity.py].
String playerIdentityKey(String name) {
  final normalized = StringNormalizer.normalize(name)
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .trim();
  final parts = normalized.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return normalized;
  final surname = _significantSurname(parts);
  if (parts.length == 1) return surname;
  final first = parts.first.replaceAll('.', '');
  final token = first.isEmpty ? '' : first[0];
  return '$surname|$token';
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
