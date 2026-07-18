import '../error/failures.dart';

/// A minimal, dependency-free `Either`-style result type.
///
/// Repositories return `Result<T>` instead of throwing, so every call site
/// is forced to consciously handle failure - no unhandled exceptions
/// bubbling out of the data layer into the UI.
sealed class Result<T> {
  const Result();

  /// Wraps a successful value.
  const factory Result.success(T value) = Success<T>;

  /// Wraps a failure.
  const factory Result.failure(Failure failure) = ResultError<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultError<T>;

  /// Returns the success value, or `null` if this is a failure.
  T? get valueOrNull => switch (this) {
        Success<T>(value: final v) => v,
        ResultError<T>() => null,
      };

  /// Pattern-matches on the result, forcing both branches to be handled.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(value: final v) => onSuccess(v),
      ResultError<T>(failure: final f) => onFailure(f),
    };
  }
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class ResultError<T> extends Result<T> {
  final Failure failure;
  const ResultError(this.failure);
}
