/// Outcome of a domain operation. UI code switches on this instead of
/// catching exceptions.
sealed class Result<T> {
  const Result();

  /// For the presentation layer, where provider state carries errors: the
  /// value, or the [AppFailure] thrown so `AsyncValue.guard` or a
  /// `FutureProvider` turns it into `AsyncError`. Domain code switches on
  /// the result instead.
  T get valueOrThrow => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;
}

/// Every failure the UI can be asked to render. Sealed so `switch` is
/// exhaustive and adding a case is a compile error until it is handled.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// The styling agent could not produce a usable outfit.
final class StylingFailure extends AppFailure {
  const StylingFailure(super.message);
}

/// A review action that the outfit's current status does not allow.
final class InvalidTransitionFailure extends AppFailure {
  const InvalidTransitionFailure(super.message);
}
