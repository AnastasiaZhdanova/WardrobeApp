import 'package:freezed_annotation/freezed_annotation.dart';

import '../../wardrobe/domain/wardrobe_item.dart';

part 'outfit_draft.freezed.dart';

/// An agent's proposal. It deliberately has no status: an agent can only
/// propose, and approval exists only in the review feature.
@freezed
abstract class OutfitDraft with _$OutfitDraft {
  const factory OutfitDraft({
    required String title,
    required String rationale,
    required List<String> itemIds,
  }) = _OutfitDraft;
}

/// Names the outfit after its base garments, e.g. "Poplin shirt & Wool
/// trousers". Shared by every agent so titles look the same whatever the
/// source.
String outfitTitle(Iterable<WardrobeItem> items) =>
    items.where((i) => i.category.isBase).map((i) => i.name).join(' & ');
