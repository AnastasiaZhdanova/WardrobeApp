import '../../../core/result.dart';
import '../../styling/domain/outfit_draft.dart';
import '../../styling/domain/outfit_rules.dart';
import '../../wardrobe/domain/wardrobe_item.dart';
import '../../wardrobe/domain/wardrobe_repository.dart';
import 'review_repository.dart';
import 'reviewed_outfit.dart';

/// The only place a review status changes:
/// `draft -> approved` and `draft -> rejected`. Both end states are final.
class StylistReview {
  StylistReview(this._reviews, this._wardrobe, {this.clock = DateTime.now});

  final ReviewRepository _reviews;
  final WardrobeRepository _wardrobe;

  /// Injected so tests get stable ids and timestamps.
  final DateTime Function() clock;

  /// Puts agent drafts in front of the stylist. Status is always `draft`.
  Future<Result<List<ReviewedOutfit>>> submit(
    String requestText,
    List<OutfitDraft> drafts,
  ) async {
    final now = clock();
    final outfits = [
      for (final (i, draft) in drafts.indexed)
        ReviewedOutfit(
          id: '${now.microsecondsSinceEpoch}-$i',
          requestText: requestText,
          title: draft.title,
          rationale: draft.rationale,
          proposedItemIds: draft.itemIds,
          itemIds: draft.itemIds,
          status: DraftStatus.draft,
          createdAt: now,
        ),
    ];
    return switch (await _reviews.saveAll(outfits)) {
      Ok() => Ok(outfits),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<ReviewedOutfit>> approve(String id) =>
      _decide(id, DraftStatus.approved);

  Future<Result<ReviewedOutfit>> reject(String id) =>
      _decide(id, DraftStatus.rejected);

  /// Replaces [from] with [to]. Only allowed on drafts, and [to] must be one
  /// of [swapOptions] so the outfit stays wearable.
  Future<Result<ReviewedOutfit>> swapItem(
    String id, {
    required String from,
    required String to,
  }) async {
    final ReviewedOutfit outfit;
    switch (await _draft(id)) {
      case Ok(:final value):
        outfit = value;
      case Err(:final failure):
        return Err(failure);
    }
    final Map<String, WardrobeItem> wardrobe;
    switch (await _wardrobe.getAll()) {
      case Ok(:final value):
        wardrobe = {for (final item in value) item.id: item};
      case Err(:final failure):
        return Err(failure);
    }

    if (!swapOptions(outfit, from, wardrobe).any((i) => i.id == to)) {
      return const Err(ValidationFailure('That item cannot be swapped in.'));
    }
    final itemIds = [for (final i in outfit.itemIds) i == from ? to : i];
    if (OutfitRules.violation(itemIds, wardrobe) case final reason?) {
      return Err(ValidationFailure(reason));
    }
    return _save(outfit.copyWith(itemIds: itemIds));
  }

  Future<Result<ReviewedOutfit>> _decide(String id, DraftStatus status) async {
    return switch (await _draft(id)) {
      Ok(:final value) => _save(
        value.copyWith(status: status, decidedAt: clock()),
      ),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<ReviewedOutfit>> _draft(String id) async {
    final result = await _reviews.getById(id);
    if (result case Ok(
      value: ReviewedOutfit(:final status),
    ) when status != DraftStatus.draft) {
      return Err(
        InvalidTransitionFailure('This outfit is already ${status.name}.'),
      );
    }
    return result;
  }

  Future<Result<ReviewedOutfit>> _save(ReviewedOutfit outfit) async =>
      switch (await _reviews.saveAll([outfit])) {
        Ok() => Ok(outfit),
        Err(:final failure) => Err(failure),
      };
}

/// Items that can replace [itemId] in [outfit]: same category and residence,
/// not already worn in the outfit. Sorted by name for a stable list.
List<WardrobeItem> swapOptions(
  ReviewedOutfit outfit,
  String itemId,
  Map<String, WardrobeItem> wardrobe,
) {
  final current = wardrobe[itemId];
  if (current == null || !outfit.itemIds.contains(itemId)) return const [];
  return wardrobe.values
      .where(
        (i) =>
            i.category == current.category &&
            i.residence == current.residence &&
            !outfit.itemIds.contains(i.id),
      )
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}
