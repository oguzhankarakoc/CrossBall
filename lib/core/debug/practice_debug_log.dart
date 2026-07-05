import 'crossball_debug_log.dart';

const _tag = 'Practice';

/// Debug-only logs for practice mode (filter console with `[Practice]`).
void practiceDebug(String message, [Object? detail]) => cbDebug(_tag, message, detail);

void practiceDebugError(String message, Object error, [StackTrace? stackTrace]) =>
    cbDebugError(_tag, message, error, stackTrace);
