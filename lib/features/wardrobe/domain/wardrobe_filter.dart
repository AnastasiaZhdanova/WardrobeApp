import 'package:freezed_annotation/freezed_annotation.dart';

import 'wardrobe_item.dart';

part 'wardrobe_filter.freezed.dart';

/// One optional value per dimension; `null` means "any".
@freezed
abstract class WardrobeFilter with _$WardrobeFilter {
  const factory WardrobeFilter({
    Season? season,
    ColorFamily? color,
    Residence? residence,
  }) = _WardrobeFilter;

  const WardrobeFilter._();

  bool get isEmpty => season == null && color == null && residence == null;

  bool matches(WardrobeItem item) =>
      (season == null || item.seasons.contains(season)) &&
      (color == null || item.color == color) &&
      (residence == null || item.residence == residence);
}
