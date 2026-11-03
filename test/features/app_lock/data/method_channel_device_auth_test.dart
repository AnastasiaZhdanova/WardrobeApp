import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/app_lock/data/method_channel_device_auth.dart';
import 'package:wardrobe_app/features/app_lock/domain/device_auth.dart';

const _channel = MethodChannel('wardrobe_app/app_lock');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  Future<AuthResult> replyWith(Object? Function(MethodCall) handler) {
    messenger.setMockMethodCallHandler(_channel, (call) async => handler(call));
    return const MethodChannelDeviceAuth().authenticate(reason: 'Unlock');
  }

  test('sends the reason and maps success', () async {
    MethodCall? received;
    final result = await replyWith((call) {
      received = call;
      return {'status': 'success'};
    });

    expect(result, isA<AuthSuccess>());
    expect(received?.method, 'authenticate');
    expect(received?.arguments, {'reason': 'Unlock'});
  });

  test('maps every status in the contract', () async {
    expect(
      await replyWith((_) => {'status': 'cancelled'}),
      isA<AuthCancelled>(),
    );
    expect(
      await replyWith((_) => {'status': 'unavailable'}),
      isA<AuthUnavailable>(),
    );
    expect(
      await replyWith((_) => {'status': 'failed', 'message': 'Locked out'}),
      isA<AuthFailed>().having((f) => f.message, 'message', 'Locked out'),
    );
  });

  test('an unknown reply fails closed', () async {
    expect(await replyWith((_) => {'status': 'maybe'}), isA<AuthFailed>());
    expect(await replyWith((_) => null), isA<AuthFailed>());
  });

  test('a platform error fails closed', () async {
    final result = await replyWith(
      (_) => throw PlatformException(code: 'busy', message: 'In progress'),
    );

    expect(result, isA<AuthFailed>());
  });

  test('a missing native side reports unavailable', () async {
    final result = await const MethodChannelDeviceAuth().authenticate(
      reason: 'Unlock',
    );

    expect(result, isA<AuthUnavailable>());
  });
}
