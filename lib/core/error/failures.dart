/// Base domain failure hierarchy for offline-first Clean Architecture.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
