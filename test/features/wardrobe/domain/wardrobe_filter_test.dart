import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_filter.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_item.dart';

const _coat = WardrobeItem(
  id: 'coat',
  name: 'Coat',
  brand: 'B',
  category: ItemCategory.outerwear,
  color: ColorFamily.brown,
  seasons: {Season.autumn, Season.winter},
  residence: Residence.city,
  formality: Formality.smart,
  imageAsset: 'coat.png',
);

void main() {
  test('empty filter matches everything', () {
    const filter = WardrobeFilter();
    expect(filter.isEmpty, isTrue);
    expect(filter.matches(_coat), isTrue);
  });

  test('season matches when the item is worn in that season', () {
    expect(const WardrobeFilter(season: Season.winter).matches(_coat), isTrue);
    expect(const WardrobeFilter(season: Season.summer).matches(_coat), isFalse);
  });

  test('color and residence must match exactly', () {
    expect(
      const WardrobeFilter(color: ColorFamily.brown).matches(_coat),
      isTrue,
    );
    expect(
      const WardrobeFilter(color: ColorFamily.black).matches(_coat),
      isFalse,
    );
    expect(
      const WardrobeFilter(residence: Residence.city).matches(_coat),
      isTrue,
    );
    expect(
      const WardrobeFilter(residence: Residence.coast).matches(_coat),
      isFalse,
    );
  });

  test('dimensions combine with AND', () {
    const filter = WardrobeFilter(
      season: Season.winter,
      residence: Residence.coast,
    );
    expect(filter.isEmpty, isFalse);
    expect(filter.matches(_coat), isFalse);
  });
}
