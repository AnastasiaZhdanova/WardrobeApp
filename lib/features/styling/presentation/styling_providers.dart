import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/providers/review_data_providers.dart';
import '../../../shared/providers/wardrobe_data_providers.dart';
import '../domain/request_outfits.dart';
import '../domain/styling_agent.dart';
import '../domain/styling_request.dart';

part 'styling_providers.g.dart';

/// Bound in the composition root (`main.dart`); tests override it.
@Riverpod(keepAlive: true)
StylingAgent stylingAgent(Ref ref) =>
    throw UnimplementedError('Override stylingAgentProvider.');

@riverpod
RequestOutfits requestOutfits(Ref ref) => RequestOutfits(
  ref.watch(wardrobeRepositoryProvider),
  ref.watch(stylingAgentProvider),
);

/// Ids of the outfits this request put into stylist review; `null` until
/// the first request.
@riverpod
class StylingController extends _$StylingController {
  int _generation = 0;

  @override
  FutureOr<List<String>?> build() => null;

  Future<void> submit(StylingRequest request) async {
    final generation = ++_generation;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() => _requestAndSubmit(request));
    // Drop stale results: the screen was closed or a newer request started.
    if (!ref.mounted || generation != _generation) return;
    state = next;
  }

  Future<List<String>> _requestAndSubmit(StylingRequest request) async {
    final requestOutfits = ref.read(requestOutfitsProvider);
    final review = ref.read(stylistReviewProvider);
    final drafts = (await requestOutfits(request)).valueOrThrow;
    final outfits = (await review.submit(request.text, drafts)).valueOrThrow;
    return [for (final outfit in outfits) outfit.id];
  }
}
