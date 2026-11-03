import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/app_lock/domain/device_auth.dart';
import 'package:wardrobe_app/features/app_lock/presentation/app_lock_controller.dart';
import 'package:wardrobe_app/features/app_lock/presentation/app_lock_gate.dart';

import '../../../fakes/fake_device_auth.dart';

final _unlockButton = find.byKey(const ValueKey('lock-unlock'));
final _secret = find.text('Secret wardrobe');

Future<void> _pump(WidgetTester tester, FakeDeviceAuth auth) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [deviceAuthProvider.overrideWithValue(auth)],
      child: const MaterialApp(
        home: AppLockGate(child: Scaffold(body: Text('Secret wardrobe'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _background(WidgetTester tester) async {
  // Stops at `hidden`: in `paused` the binding stops producing frames.
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

Future<void> _foreground(WidgetTester tester) async {
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('prompts on launch and unlocks on success', (tester) async {
    final auth = FakeDeviceAuth.success();
    await _pump(tester, auth);

    expect(auth.prompts, 1);
    expect(_unlockButton, findsNothing);
    expect(_secret.hitTestable(), findsOneWidget);
  });

  testWidgets('cancel keeps it locked until the user retries', (tester) async {
    final auth = FakeDeviceAuth([const AuthCancelled(), const AuthSuccess()]);
    await _pump(tester, auth);

    expect(_unlockButton, findsOneWidget);
    expect(_secret.hitTestable(), findsNothing);

    await tester.tap(_unlockButton);
    await tester.pumpAndSettle();

    expect(_unlockButton, findsNothing);
    expect(auth.prompts, 2);
  });

  testWidgets('failure shows the reason', (tester) async {
    await _pump(tester, FakeDeviceAuth([const AuthFailed('Locked out')]));

    expect(find.text('Locked out'), findsOneWidget);
    expect(_unlockButton, findsOneWidget);
  });

  group('device without passcode or biometrics', () {
    final message = find.byKey(const ValueKey('lock-unavailable'));

    testWidgets('lock cannot be turned on and a message says why', (
      tester,
    ) async {
      await _pump(tester, FakeDeviceAuth([const AuthUnavailable()]));

      expect(_unlockButton, findsNothing);
      expect(_secret.hitTestable(), findsOneWidget);
      expect(message, findsOneWidget);
      expect(find.textContaining('App lock is off'), findsOneWidget);
    });

    testWidgets('backgrounding does not lock', (tester) async {
      final auth = FakeDeviceAuth([const AuthUnavailable()]);
      await _pump(tester, auth);

      await _background(tester);
      expect(_unlockButton, findsNothing);

      await _foreground(tester);
      expect(_unlockButton, findsNothing);
      expect(_secret.hitTestable(), findsOneWidget);
      expect(message, findsOneWidget);
    });

    testWidgets('turns on once a passcode is set up', (tester) async {
      final auth = FakeDeviceAuth([
        const AuthUnavailable(),
        const AuthCancelled(),
      ]);
      await _pump(tester, auth);

      // The owner leaves to set a passcode and comes back.
      await _background(tester);
      await _foreground(tester);

      expect(auth.prompts, 2);
      expect(_unlockButton, findsOneWidget);
      expect(_secret.hitTestable(), findsNothing);
      expect(message, findsNothing);
    });

    test('lock() leaves the controller unavailable', () async {
      final container = ProviderContainer(
        overrides: [
          deviceAuthProvider.overrideWithValue(
            FakeDeviceAuth([const AuthUnavailable()]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(appLockControllerProvider.notifier);

      await controller.unlock();
      controller.lock();

      expect(container.read(appLockControllerProvider), isA<LockUnavailable>());
    });
  });

  testWidgets('locks when backgrounded and prompts again on return', (
    tester,
  ) async {
    final auth = FakeDeviceAuth.success();
    await _pump(tester, auth);

    await _background(tester);
    expect(_unlockButton, findsOneWidget);

    await _foreground(tester);
    expect(auth.prompts, 2);
    expect(_unlockButton, findsNothing);
  });

  testWidgets('content is covered while inactive, without locking', (
    tester,
  ) async {
    await _pump(tester, FakeDeviceAuth.success());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.text('Your wardrobe is private.'), findsOneWidget);
    expect(_unlockButton, findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Your wardrobe is private.'), findsNothing);
  });

  testWidgets('a success arriving after backgrounding does not unlock', (
    tester,
  ) async {
    final auth = FakeDeviceAuth.success();
    await _pump(tester, auth);
    auth.hold = true;

    // Return to the app: a prompt opens but has not answered yet.
    await _background(tester);
    await _foreground(tester);
    expect(auth.prompts, 2);

    // Backgrounded again before it answers; then the answer is a success.
    await _background(tester);
    auth.release();
    await tester.pump();

    expect(_unlockButton, findsOneWidget);
    expect(_secret.hitTestable(), findsNothing);
  });
}
