import 'dart:async';

import 'package:wardrobe_app/features/app_lock/domain/device_auth.dart';

/// Answers each prompt with the next of [results]; the last one repeats.
/// While [hold] is set, prompts wait until [release] is called.
class FakeDeviceAuth implements DeviceAuth {
  FakeDeviceAuth(this.results, {this.hold = false});

  FakeDeviceAuth.success() : this([const AuthSuccess()]);

  final List<AuthResult> results;
  bool hold;
  int prompts = 0;
  Completer<void>? _gate;

  void release() => _gate?.complete();

  @override
  Future<AuthResult> authenticate({required String reason}) async {
    final result = results[prompts.clamp(0, results.length - 1)];
    prompts++;
    if (hold) await (_gate = Completer<void>()).future;
    return result;
  }
}
