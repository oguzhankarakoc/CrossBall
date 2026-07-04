import 'package:flutter/foundation.dart';

/// Debug-only logs for practice mode diagnostics (filter Xcode/console with `[Practice]`).
void practiceDebug(String message, [Object? detail]) {
  if (!kDebugMode) return;
  final suffix = detail == null ? '' : ' | $detail';
  debugPrint('[Practice] $message$suffix');
}

void practiceDebugError(String message, Object error, [StackTrace? stackTrace]) {
  if (!kDebugMode) return;
  debugPrint('[Practice] ERROR $message | $error');
  if (stackTrace != null) {
    debugPrint('[Practice] $stackTrace');
  }
}
