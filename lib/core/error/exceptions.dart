/// Low-level local storage exception mapped to domain [Failure]s by repositories.
final class LocalStorageException implements Exception {
  const LocalStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'LocalStorageException: $message';
}
