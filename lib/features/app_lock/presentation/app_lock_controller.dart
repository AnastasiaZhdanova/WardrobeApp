import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/device_auth.dart';

part 'app_lock_controller.g.dart';

sealed class AppLockState {
  const AppLockState();

  /// Whether the app's content is visible and usable.
  bool get isOpen => this is Unlocked || this is LockUnavailable;
}

final class Locked extends AppLockState {
  const Locked([this.message]);

  /// Why the last attempt did not unlock, if it failed.
  final String? message;
}

final class Authenticating extends AppLockState {
  const Authenticating();
}

final class Unlocked extends AppLockState {
  const Unlocked();
}

/// The device has no passcode or biometrics, so the lock cannot be turned
/// on. The app stays open with a message instead of locking the owner out,
/// and [AppLockController.lock] does nothing until the device can verify
/// its owner.
final class LockUnavailable extends AppLockState {
  const LockUnavailable();
}

/// Bound in the composition root (`main.dart`); tests override it.
@Riverpod(keepAlive: true)
DeviceAuth deviceAuth(Ref ref) =>
    throw UnimplementedError('Override deviceAuthProvider.');

/// Starts locked on every cold start; `AppLockGate` calls [lock] when the app
/// goes to the background and [unlock] when it returns.
@Riverpod(keepAlive: true)
class AppLockController extends _$AppLockController {
  int _attempt = 0;

  @override
  AppLockState build() => const Locked();

  void lock() {
    // Invalidates any prompt still in flight.
    _attempt++;
    if (state is LockUnavailable) return;
    state = const Locked();
  }

  /// Prompts the owner. From [LockUnavailable] this re-checks the device
  /// without covering the app: if a passcode was set up in the meantime,
  /// the prompt appears and the lock is on from then on.
  Future<void> unlock() async {
    final recheck = state is LockUnavailable;
    if (state is! Locked && !recheck) return;
    final attempt = ++_attempt;
    if (!recheck) state = const Authenticating();
    final result = await ref
        .read(deviceAuthProvider)
        .authenticate(reason: 'Unlock your private wardrobe');
    // Backgrounded while the prompt was open: a late success must not unlock.
    if (attempt != _attempt) return;
    state = switch (result) {
      AuthSuccess() => const Unlocked(),
      AuthUnavailable() => const LockUnavailable(),
      AuthCancelled() => const Locked(),
      AuthFailed(:final message) => Locked(message),
    };
  }
}
