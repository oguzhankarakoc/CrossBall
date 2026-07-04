/// Thrown when a live puzzle cannot be loaded from the backend.
class PuzzleFetchException implements Exception {
  const PuzzleFetchException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
