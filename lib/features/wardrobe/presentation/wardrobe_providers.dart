import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result.dart';
import '../../../shared/providers/wardrobe_data_providers.dart';
import '../domain/wardrobe_filter.dart';
import '../domain/wardrobe_item.dart';

part 'wardrobe_providers.g.dart';

/// Read from the already-loaded wardrobe, so opening an item costs no query
/// and its Hero image lands on content, not on a loading frame.
@riverpod
AsyncValue<WardrobeItem> wardrobeItem(Ref ref, String id) =>
    ref.watch(wardrobeByIdProvider).whenData((byId) {
      final item = byId[id];
      // `whenData` turns this into `AsyncError`.
      if (item == null) {
        throw NotFoundFailure('Item $id is not in the wardrobe.');
      }
      return item;
    });

@riverpod
class WardrobeFilterController extends _$WardrobeFilterController {
  @override
  WardrobeFilter build() => const WardrobeFilter();

  void toggleSeason(Season season) =>
      state = state.copyWith(season: state.season == season ? null : season);

  void toggleColor(ColorFamily color) =>
      state = state.copyWith(color: state.color == color ? null : color);

  void toggleResidence(Residence residence) => state = state.copyWith(
    residence: state.residence == residence ? null : residence,
  );

  void clear() => state = const WardrobeFilter();
}

@riverpod
AsyncValue<List<WardrobeItem>> filteredWardrobe(Ref ref) {
  final filter = ref.watch(wardrobeFilterControllerProvider);
  return ref
      .watch(wardrobeItemsProvider)
      .whenData((items) => items.where(filter.matches).toList());
}
