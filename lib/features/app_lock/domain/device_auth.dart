/// Outcome of asking the OS to verify the device owner.
sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

/// The user or the system dismissed the prompt.
final class AuthCancelled extends AuthResult {
  const AuthCancelled();
}

/// Verification failed, e.g. too many attempts (lockout).
final class AuthFailed extends AuthResult {
  const AuthFailed(this.message);

  final String message;
}

/// Neither biometrics nor a device passcode is set up.
final class AuthUnavailable extends AuthResult {
  const AuthUnavailable();
}

abstract interface class DeviceAuth {
  /// Biometrics with the device passcode as fallback.
  Future<AuthResult> authenticate({required String reason});
}
