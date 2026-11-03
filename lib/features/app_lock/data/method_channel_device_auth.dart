import 'package:flutter/services.dart';

import '../domain/device_auth.dart';

/// Talks to `AppLockHandler.kt` (Android, BiometricPrompt) and
/// `AppLockPlugin` in `AppDelegate.swift` (iOS, LocalAuthentication).
///
/// Contract: method `authenticate` with `{reason: String}` returns
/// `{status: success|cancelled|failed|unavailable, message: String?}`.
class MethodChannelDeviceAuth implements DeviceAuth {
  const MethodChannelDeviceAuth([
    this._channel = const MethodChannel('wardrobe_app/app_lock'),
  ]);

  final MethodChannel _channel;

  @override
  Future<AuthResult> authenticate({required String reason}) async {
    try {
      final reply = await _channel.invokeMapMethod<String, Object?>(
        'authenticate',
        {'reason': reason},
      );
      return switch (reply) {
        {'status': 'success'} => const AuthSuccess(),
        {'status': 'cancelled'} => const AuthCancelled(),
        {'status': 'unavailable'} => const AuthUnavailable(),
        {'status': 'failed', 'message': final String message} => AuthFailed(
          message,
        ),
        _ => const AuthFailed('Unexpected reply from the platform.'),
      };
    } on PlatformException catch (e) {
      return AuthFailed(e.message ?? e.code);
    } on MissingPluginException {
      // No native side, e.g. an unsupported platform.
      return const AuthUnavailable();
    }
  }
}
