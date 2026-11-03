import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result.dart';
import '../../../shared/providers/review_data_providers.dart';
import '../domain/reviewed_outfit.dart';
import '../domain/stylist_review.dart';

part 'review_providers.g.dart';

/// In-flight state of the stylist's actions on one outfit. The outfit itself
/// comes from [reviewQueueProvider]; this only reports progress and errors.
@riverpod
class ReviewActions extends _$ReviewActions {
  @override
  FutureOr<void> build(String outfitId) {}

  Future<void> approve() => _run((review) => review.approve(outfitId));

  Future<void> reject() => _run((review) => review.reject(outfitId));

  Future<void> swap({required String from, required String to}) =>
      _run((review) => review.swapItem(outfitId, from: from, to: to));

  Future<void> _run(
    Future<Result<ReviewedOutfit>> Function(StylistReview) action,
  ) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final review = ref.read(stylistReviewProvider);
    final next = await AsyncValue.guard(
      () async => (await action(review)).valueOrThrow,
    );
    if (!ref.mounted) return;
    // The updated outfit arrives through [reviewQueueProvider].
    state = next.whenData((_) {});
  }
}
