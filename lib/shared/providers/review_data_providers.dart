import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/review/domain/review_repository.dart';
import '../../features/review/domain/reviewed_outfit.dart';
import '../../features/review/domain/stylist_review.dart';
import 'wardrobe_data_providers.dart';

part 'review_data_providers.g.dart';

/// Bound in the composition root (`main.dart`); tests override it.
@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) =>
    throw UnimplementedError('Override reviewRepositoryProvider.');

@riverpod
StylistReview stylistReview(Ref ref) => StylistReview(
  ref.watch(reviewRepositoryProvider),
  ref.watch(wardrobeRepositoryProvider),
);

@riverpod
Stream<List<ReviewedOutfit>> reviewQueue(Ref ref) =>
    ref.watch(reviewRepositoryProvider).watchAll();

@riverpod
AsyncValue<ReviewedOutfit?> reviewedOutfit(Ref ref, String id) => ref
    .watch(reviewQueueProvider)
    .whenData((all) => all.where((o) => o.id == id).firstOrNull);
