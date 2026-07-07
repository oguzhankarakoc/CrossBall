/// Thrown when a live puzzle cannot be loaded from the backend.
class PuzzleFetchException implements Exception {
  const PuzzleFetchException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.retryAfterSeconds,
    this.rolloutStartedAt,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  final int? retryAfterSeconds;
  final DateTime? rolloutStartedAt;

  bool get isGenerationInProgress => errorCode == 'generation_in_progress';

  bool get isGenerationFailed => errorCode == 'generation_failed';

  bool get isDailyAlreadyCompleted => errorCode == 'daily_already_completed';

  @override
  String toString() => message;
}
