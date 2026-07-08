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

  bool get isDailyAlreadyCompleted =>
      (errorCode ?? message).contains('daily_already_completed');

  @override
  String toString() => message;
}

/// Thrown when a live hint cannot be loaded from the backend.
class HintRequestException implements Exception {
  const HintRequestException(
    this.message, {
    this.statusCode,
    this.errorCode,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;

  bool get isAdTokenRequired =>
      errorCode == 'ad_token_required' || errorCode == 'invalid_ad_token';

  bool get isHintLimitReached => errorCode == 'hint_limit_reached';

  @override
  String toString() => message;
}
