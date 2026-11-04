import 'package:flutter/foundation.dart';

import 'app_exception.dart';

/// Centralised error-handling utilities.
///
/// Presentation widgets should call [userMessage] to obtain a human-
/// readable string without exposing stack traces in production builds.
/// Log technical details through [logError] for debugging.
abstract class ErrorHandler {
  ErrorHandler._();

  /// Returns a user-facing message for [error].
  ///
  /// Keeps technical details hidden from the user in release builds.
  static String userMessage(Object error) {
    if (error is ValidationException) return error.message;
    if (error is StorageException) {
      return 'Could not save or load data. Please try again.';
    }
    if (error is NotFoundException) return error.message;
    if (error is StateException) return error.message;
    if (error is AppException) return error.message;

    // Generic fallback — intentionally vague for release builds.
    return 'Something went wrong. Please try again.';
  }

  /// Logs an error with its stack trace in debug builds.
  ///
  /// In production, use a proper crash-reporting integration here
  /// (e.g. Firebase Crashlytics) once it is added to the project.
  static void logError(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    if (kDebugMode) {
      final prefix = context != null ? '[$context] ' : '';
      debugPrint('${prefix}ERROR: $error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
