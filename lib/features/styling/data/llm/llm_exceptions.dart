/// Why an LLM call failed. [retryable] decides whether one more attempt is
/// worth it before falling back to the offline agent.
sealed class LlmException implements Exception {
  const LlmException(this.message, {required this.retryable});

  final String message;
  final bool retryable;

  @override
  String toString() => '$runtimeType: $message';
}

final class LlmTimeoutException extends LlmException {
  const LlmTimeoutException() : super('Request timed out.', retryable: true);
}

final class LlmHttpException extends LlmException {
  LlmHttpException(this.statusCode)
    : super(
        'HTTP $statusCode',
        retryable: statusCode == 408 || statusCode == 429 || statusCode >= 500,
      );

  final int statusCode;
}

final class LlmNetworkException extends LlmException {
  const LlmNetworkException(super.message) : super(retryable: true);
}

/// The model declined (`stop_reason: refusal`). Retrying will not help.
final class LlmRefusalException extends LlmException {
  const LlmRefusalException() : super('Model declined.', retryable: false);
}

/// The response did not match the outfit schema, or named unknown items.
final class LlmFormatException extends LlmException {
  const LlmFormatException(super.message) : super(retryable: true);
}
