import 'package:flutter/foundation.dart';

/// Writes an error and its stack trace in the console, in debug builds only.
///
/// In a release build, anyone can open the console of the browser: the details of the
/// errors (stack traces, answers of the API) stay out of it.
void logErrorInDebug(String context, Object error, StackTrace stackTrace) {
  if (!kDebugMode) {
    return;
  }

  debugPrint('$context error: $error\n$stackTrace');
}
