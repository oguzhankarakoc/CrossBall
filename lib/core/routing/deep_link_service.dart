import 'app_routes.dart';

/// Maps challenge deep / universal links to in-app GoRouter paths.
abstract final class DeepLinkService {
  /// Supported:
  /// - crossball://challenge/abc123
  /// - https://…/challenge.html?c=abc123
  static String? routeFromUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    if (scheme == 'crossball') {
      return _fromCustomScheme(uri);
    }

    if (scheme == 'https' || scheme == 'http') {
      return _fromHttps(uri);
    }

    return null;
  }

  static String? _fromCustomScheme(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final mode = uri.queryParameters['mode'];

    // Marketing / App Store screenshot deep links (crossball://home, etc.)
    switch (host) {
      case 'home':
        return AppRoutes.home;
      case 'leaderboard':
        return AppRoutes.leaderboard;
      case 'community':
        return AppRoutes.community;
      case 'stats':
        return AppRoutes.stats;
      case 'premium':
        return AppRoutes.premium;
      case 'practice':
        return AppRoutes.practiceHub;
      case 'puzzle':
        final puzzleMode = mode ?? 'daily';
        return '${AppRoutes.puzzle}?mode=$puzzleMode';
      case 'challenge':
        final id = _challengeIdFromUri(uri, segments);
        if (id != null && id.isNotEmpty) {
          return '${AppRoutes.puzzle}?mode=challenge&id=$id';
        }
    }

    if (segments.isNotEmpty && segments.first.toLowerCase() == 'challenge') {
      final id = segments.length > 1 ? segments[1] : uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        return '${AppRoutes.puzzle}?mode=challenge&id=$id';
      }
    }

    return null;
  }

  static String? _fromHttps(Uri uri) {
    final code = uri.queryParameters['c'] ??
        uri.queryParameters['code'] ??
        uri.queryParameters['id'];
    if (code != null && code.isNotEmpty) {
      final path = uri.path.toLowerCase();
      if (path.contains('challenge') || path.endsWith('/c') || path.contains('/c/')) {
        return '${AppRoutes.puzzle}?mode=challenge&id=$code';
      }
      // challenge.html?c=…
      if (uri.pathSegments.any((s) => s.toLowerCase().contains('challenge'))) {
        return '${AppRoutes.puzzle}?mode=challenge&id=$code';
      }
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final cIndex = segments.indexWhere((s) => s.toLowerCase() == 'c');
    if (cIndex >= 0 && cIndex + 1 < segments.length) {
      return '${AppRoutes.puzzle}?mode=challenge&id=${segments[cIndex + 1]}';
    }

    return null;
  }

  static String? _challengeIdFromUri(Uri uri, List<String> segments) {
    if (uri.queryParameters['id'] case final id?) return id;
    if (segments.isNotEmpty) return segments.first;
    final path = uri.path.replaceFirst('/', '');
    return path.isNotEmpty ? path : null;
  }
}
