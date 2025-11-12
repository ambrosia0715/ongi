import 'result.dart';

/// Result 확장 메서드
extension ResultExtension<T> on Result<T> {
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) {
    return switch (this) {
      Success(data: final data) => success(data),
      Failure(message: final message, error: final error) =>
        failure(message, error),
    };
  }
}

