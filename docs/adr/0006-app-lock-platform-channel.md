# 0006. App lock through a hand-written MethodChannel

Status: Accepted

## Context
The wardrobe is personal. The app should lock on launch and when it goes
to the background, unlock with the platform's biometrics or the device
passcode, and never show content in the app switcher.

## Threat model
The app lock **protects against casual shoulder surfing only**: someone
picking up an unlocked phone, or glancing at the app switcher. It is
**not a data-protection feature.**

- **Local data is not encrypted.** The drift database and image assets
  are stored in plain form in the app sandbox. Anyone who can read the
  sandbox can read the wardrobe and review history without passing the
  lock: a backup, a jailbroken or rooted device, or a debug build.
- **It doesn't protect against** malware on the device, forensic
  extraction, or someone who knows the device passcode. The passcode is
  always accepted as a fallback.
- **It isn't an authorization check.** Whoever unlocks acts as the
  stylist (ADR 0004).

## Decision
- **Channel:** one channel, `wardrobe_app/app_lock`, with one method:
  `authenticate({reason})` returns
  `{status: success|cancelled|failed|unavailable, message?}`.
- **Android:** `AppLockHandler.kt` uses `androidx.biometric`'s
  `BiometricPrompt` with `BIOMETRIC_WEAK | DEVICE_CREDENTIAL`.
  - `MainActivity` is a `FlutterFragmentActivity`, because the prompt
    needs a `FragmentActivity`.
  - It replies `unavailable` without showing a prompt when
    `BiometricManager.canAuthenticate` fails.
- **iOS:** `AppLockPlugin` in `ios/Runner/AppDelegate.swift` uses
  `LAContext` with `.deviceOwnerAuthentication` (Face ID / Touch ID, then
  passcode).
  - It creates a new context per attempt and replies on the main queue.
  - It replies `unavailable` when `canEvaluatePolicy` fails.
  - `NSFaceIDUsageDescription` is set in `Info.plist`.
- **Dart:** `MethodChannelDeviceAuth` implements the domain interface
  `DeviceAuth` and maps replies to the sealed `AuthResult`. Any unexpected
  reply or `PlatformException` counts as a failure (fail closed).
- **`AppLockGate`** wraps the router:
  - the app is locked on cold start;
  - it locks on `AppLifecycleState.hidden`;
  - it covers content while `inactive`, for the app switcher snapshot;
  - it prompts again on return.

  `AppLockController` ignores a late result from an older prompt
  (attempt counter).
- **No passcode or biometrics on the device:** the controller enters
  `LockUnavailable`.
  - The lock cannot be turned on, and `lock()` does nothing in that state.
  - The app stays usable with a persistent message: "App lock is off:
    this device has no passcode, Face ID or fingerprint set up…".
  - On each return to the foreground the device is checked again, so the
    lock turns on once the owner sets up a passcode.

  There is no in-app on/off switch. The lock is on whenever the device
  supports it.

## Alternatives considered
- **`local_auth` plugin:** less code, but it hides exactly the native
  details this feature is meant to show, and adds a dependency.
- **Pigeon:** type-safe generated channels. This is worth it for several
  methods, and overkill for one.
- **Locking on `inactive`:** the Face ID sheet itself makes the app
  inactive, so the lock loops.
- **A lock route instead of an overlay:** loses the navigation stack on
  every lock.
- **Blocking the app when no passcode is set:** safer for the data, but
  it would lock the owner out of their own wardrobe, and the lock adds no
  real protection on such a device anyway.

## Consequences
Positive:
- Navigation state survives a lock, because the app stays mounted under
  the overlay.
- The channel contract is small and documented on both native sides.
- The "unavailable" branch is explicit state, with tests: no lock, a
  visible message, no locking on background, and the lock turns on once a
  passcode exists (`app_lock_gate_test.dart`).

Negative:
- **Data isn't protected** (see the threat model). The name "app lock"
  was chosen so the feature doesn't suggest otherwise.
- **The passcode fallback** means the lock is only as strong as the device
  passcode. `BIOMETRIC_WEAK` is fine for a UI gate, but not for unlocking
  cryptographic keys.
- **Availability is detected by asking for authentication.** There is no
  separate `isAvailable` call, so the re-check on return shows a prompt
  as soon as a passcode exists.
- **Only the Dart side is tested** (`method_channel_device_auth_test.dart`
  with a mocked channel, `app_lock_gate_test.dart`). The native code has
  no XCTest or Robolectric tests. CI does not build it; it was compiled
  with local debug builds and checked by hand.
- **No grace period:** it prompts every time the app returns from the
  background.
- **No switch:** owners can't turn the lock off.

## What I would change at production scale
Make it a data-protection feature:
- encrypt the database (SQLCipher via drift) with a key held in the
  Keychain / Android Keystore and bound to biometric authentication
  (`BIOMETRIC_STRONG`);
- exclude the database from unencrypted backups.

Then:
- add an `isAvailable` method, a persisted on/off setting and a short
  re-lock grace period;
- move to Pigeon;
- add native unit tests.
