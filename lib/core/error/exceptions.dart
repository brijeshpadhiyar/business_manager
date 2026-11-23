/// Low-level local storage exception mapped to domain [Failure]s by repositories.
final class LocalStorageException implements Exception {
  const LocalStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'LocalStorageException: $message';
}

/// Typed domain validation error carrying a machine-readable [code] so
/// presentation layers can map errors to localized user-facing messages.
final class DomainValidationException implements Exception {
  const DomainValidationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'DomainValidationException($code): $message';
}
