import '../../wardrobe/domain/wardrobe_item.dart';

/// Rules every outfit must satisfy, whoever built it (an agent or a stylist
/// swapping an item).
abstract final class OutfitRules {
  static const maxDrafts = 3;

  /// Returns why [itemIds] is not a wearable outfit, or `null` if it is.
  static String? violation(
    List<String> itemIds,
    Map<String, WardrobeItem> wardrobe,
  ) {
    if (itemIds.isEmpty) return 'Outfit has no items.';
    if (itemIds.toSet().length != itemIds.length) {
      return 'Outfit repeats an item.';
    }
    final items = <WardrobeItem>[];
    for (final id in itemIds) {
      final item = wardrobe[id];
      if (item == null) return 'Item $id is not in the wardrobe.';
      items.add(item);
    }
    if (items.map((i) => i.residence).toSet().length > 1) {
      return 'Items are in different residences.';
    }
    final categories = items.map((i) => i.category).toList();
    if (categories.toSet().length != categories.length) {
      return 'Outfit has two items of the same category.';
    }
    final hasDress = categories.contains(ItemCategory.dress);
    final hasTop = categories.contains(ItemCategory.top);
    final hasBottom = categories.contains(ItemCategory.bottom);
    if (hasDress && (hasTop || hasBottom)) {
      return 'A dress is not combined with a top or bottom.';
    }
    if (!hasDress && !(hasTop && hasBottom)) {
      return 'Outfit needs a dress, or a top and a bottom.';
    }
    return null;
  }
}
