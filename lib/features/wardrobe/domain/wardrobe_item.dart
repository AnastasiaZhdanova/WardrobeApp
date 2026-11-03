import 'package:freezed_annotation/freezed_annotation.dart';

part 'wardrobe_item.freezed.dart';

enum ItemCategory {
  top,
  bottom,
  dress,
  outerwear,
  shoes,
  accessory;

  /// The garments an outfit is built around: a dress, or a top and a bottom.
  bool get isBase => this == top || this == bottom || this == dress;
}

enum Season { spring, summer, autumn, winter }

enum ColorFamily {
  black,
  white,
  beige,
  grey,
  navy,
  brown,
  red,
  green,
  blue,
  pink,
}

/// Where the item physically lives. A client with several homes can only
/// wear what is in the wardrobe they are standing in front of.
enum Residence { city, country, coast }

enum Formality { casual, smart, formal }

@freezed
abstract class WardrobeItem with _$WardrobeItem {
  const factory WardrobeItem({
    required String id,
    required String name,
    required String brand,
    required ItemCategory category,
    required ColorFamily color,
    required Set<Season> seasons,
    required Residence residence,
    required Formality formality,
    required String imageAsset,
    @Default('') String notes,
  }) = _WardrobeItem;
}
