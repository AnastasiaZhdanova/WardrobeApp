import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/core/result.dart';
import 'package:wardrobe_app/features/review/domain/reviewed_outfit.dart';
import 'package:wardrobe_app/features/review/domain/stylist_review.dart';
import 'package:wardrobe_app/features/styling/domain/outfit_draft.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';

import '../../../fakes/fake_review_repository.dart';
import '../../../fakes/fake_wardrobe_repository.dart';

const _draft = OutfitDraft(
  title: 'Shirt & trousers',
  rationale: 'Smart.',
  itemIds: ['itm_poplin_shirt', 'itm_wool_trousers', 'itm_leather_loafers'],
);
final _now = DateTime.utc(2026, 11, 2, 10);

void main() {
  late FakeReviewRepository reviews;
  late StylistReview review;
  late String id;

  setUp(() async {
    reviews = FakeReviewRepository();
    review = StylistReview(
      reviews,
      FakeWardrobeRepository(),
      clock: () => _now,
    );
    final submitted = await review.submit('Office', [_draft]);
    id = (submitted as Ok<List<ReviewedOutfit>>).value.single.id;
  });

  ReviewedOutfit stored() => reviews.all.single;

  test('submit stores agent drafts as drafts, never approved', () {
    expect(stored().status, DraftStatus.draft);
    expect(stored().itemIds, _draft.itemIds);
    expect(stored().proposedItemIds, _draft.itemIds);
    expect(stored().requestText, 'Office');
    expect(stored().decidedAt, isNull);
  });

  test('draft -> approved records the decision time', () async {
    final result = await review.approve(id);

    expect(result, isA<Ok<ReviewedOutfit>>());
    expect(stored().status, DraftStatus.approved);
    expect(stored().decidedAt, _now);
  });

  test('draft -> rejected', () async {
    await review.reject(id);

    expect(stored().status, DraftStatus.rejected);
  });

  test('approved and rejected are final', () async {
    await review.approve(id);

    final reject = await review.reject(id);
    final approveAgain = await review.approve(id);

    expect((reject as Err).failure, isA<InvalidTransitionFailure>());
    expect((approveAgain as Err).failure, isA<InvalidTransitionFailure>());
    expect(stored().status, DraftStatus.approved);
  });

  test('swap replaces one item and keeps the proposal for audit', () async {
    final result = await review.swapItem(
      id,
      from: 'itm_poplin_shirt',
      to: 'itm_cashmere_crew',
    );

    expect(result, isA<Ok<ReviewedOutfit>>());
    expect(stored().itemIds, [
      'itm_cashmere_crew',
      'itm_wool_trousers',
      'itm_leather_loafers',
    ]);
    expect(stored().proposedItemIds, _draft.itemIds);
    expect(stored().isEditedByStylist, isTrue);
    expect(stored().status, DraftStatus.draft);
  });

  test('swap to another category or residence is rejected', () async {
    final otherCategory = await review.swapItem(
      id,
      from: 'itm_poplin_shirt',
      to: 'itm_camel_coat',
    );
    final otherResidence = await review.swapItem(
      id,
      from: 'itm_poplin_shirt',
      to: 'itm_linen_shirt',
    );

    expect((otherCategory as Err).failure, isA<ValidationFailure>());
    expect((otherResidence as Err).failure, isA<ValidationFailure>());
    expect(stored().itemIds, _draft.itemIds);
  });

  test('swap after approval is not allowed', () async {
    await review.approve(id);

    final result = await review.swapItem(
      id,
      from: 'itm_poplin_shirt',
      to: 'itm_cashmere_crew',
    );

    expect((result as Err).failure, isA<InvalidTransitionFailure>());
  });

  test('unknown outfit is NotFound', () async {
    final result = await review.approve('missing');

    expect((result as Err).failure, isA<NotFoundFailure>());
  });

  test('swapOptions: same category and residence, not already worn', () {
    final wardrobe = {for (final i in seedWardrobe) i.id: i};

    final options = swapOptions(stored(), 'itm_poplin_shirt', wardrobe);

    expect(options.map((i) => i.id), ['itm_cashmere_crew', 'itm_silk_blouse']);
    expect(swapOptions(stored(), 'itm_camel_coat', wardrobe), isEmpty);
  });
}
