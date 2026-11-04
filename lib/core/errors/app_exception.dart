/// Application-level exception types for BillMate.
///
/// Use these types when throwing errors that may need to be presented
/// to the user or handled differently in different layers. Catch
/// [AppException] to handle all app-defined errors uniformly.
abstract class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Human-readable description suitable for logging.
  final String message;

  /// Optional underlying exception or error.
  final Object? cause;

  @override
  String toString() => cause != null
      ? '$runtimeType: $message (caused by: $cause)'
      : '$runtimeType: $message';
}

/// Thrown when a database read, write, or migration fails.
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Thrown when user-supplied data fails validation.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause})
    : fieldErrors = const {};

  /// Field-level validation errors keyed by field name.
  final Map<String, String> fieldErrors;

  const ValidationException.withFields(
    super.message, {
    required this.fieldErrors,
    super.cause,
  });
}

/// Thrown when a requested resource (bill, setting) is not found.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

/// Thrown when an operation fails due to an unexpected state.
class StateException extends AppException {
  const StateException(super.message, {super.cause});
}
