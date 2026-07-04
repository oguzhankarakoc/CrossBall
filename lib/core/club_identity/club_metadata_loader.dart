import 'dart:convert';

import 'package:flutter/services.dart';

import 'club_identity.dart';

/// Loads optional bundled club metadata from assets/clubs/.
/// Procedural badges remain the render path; JSON extends the registry at runtime.
abstract final class ClubMetadataLoader {
  static const _manifestPath = 'assets/clubs/manifest.json';
  static final Map<String, ClubIdentity> overrides = {};

  static Future<void> loadBundled() async {
    try {
      final manifestRaw = await rootBundle.loadString(_manifestPath);
      final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
      final slugs = (manifest['clubs'] as List<dynamic>? ?? []).cast<String>();
      for (final slug in slugs) {
        final identity = await _loadClub(slug);
        if (identity != null) overrides[slug] = identity;
      }
    } catch (_) {
      // Manifest optional — registry + DB remain authoritative.
    }
  }

  static Future<ClubIdentity?> _loadClub(String slug) async {
    try {
      final metaRaw = await rootBundle.loadString('assets/clubs/$slug/metadata.json');
      final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
      return ClubIdentity.fromJson(meta);
    } catch (_) {
      return null;
    }
  }
}
