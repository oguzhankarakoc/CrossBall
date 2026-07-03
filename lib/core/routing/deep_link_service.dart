import 'app_routes.dart';

/// Maps `crossball://` URIs to in-app GoRouter paths.
abstract final class DeepLinkService {
  /// crossball://challenge/abc123 → /puzzle?mode=challenge&id=abc123
  static String? routeFromUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'crossball') return null;

    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (host == 'challenge') {
      final id = _challengeIdFromUri(uri, segments);
      if (id != null && id.isNotEmpty) {
        return '${AppRoutes.puzzle}?mode=challenge&id=$id';
      }
    }

    // crossball:///challenge/abc123 (no host)
    if (segments.isNotEmpty && segments.first.toLowerCase() == 'challenge') {
      final id = segments.length > 1 ? segments[1] : uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        return '${AppRoutes.puzzle}?mode=challenge&id=$id';
      }
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
