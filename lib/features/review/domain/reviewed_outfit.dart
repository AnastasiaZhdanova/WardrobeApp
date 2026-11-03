import 'package:freezed_annotation/freezed_annotation.dart';

part 'reviewed_outfit.freezed.dart';

enum DraftStatus { draft, approved, rejected }

/// An agent draft under stylist control. Created only by
/// `StylistReview.submit`, and its status changes only through
/// `StylistReview.approve` / `reject`.
@freezed
abstract class ReviewedOutfit with _$ReviewedOutfit {
  const factory ReviewedOutfit({
    required String id,
    required String requestText,
    required String title,
    required String rationale,

    /// What the agent proposed; kept so edits stay auditable.
    required List<String> proposedItemIds,

    /// What the stylist will approve, after any swaps.
    required List<String> itemIds,
    required DraftStatus status,
    required DateTime createdAt,
    DateTime? decidedAt,
  }) = _ReviewedOutfit;

  const ReviewedOutfit._();

  bool get isEditedByStylist => proposedItemIds.join(',') != itemIds.join(',');
}
