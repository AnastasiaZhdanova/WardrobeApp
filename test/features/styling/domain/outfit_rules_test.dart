import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/styling/domain/outfit_rules.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';

final _wardrobe = {for (final item in seedWardrobe) item.id: item};

String? _check(List<String> ids) => OutfitRules.violation(ids, _wardrobe);

void main() {
  test('accepts top + bottom + extras from one residence', () {
    expect(
      _check([
        'itm_poplin_shirt',
        'itm_wool_trousers',
        'itm_leather_loafers',
        'itm_camel_coat',
      ]),
      isNull,
    );
  });

  test('accepts a dress on its own', () {
    expect(_check(['itm_evening_dress']), isNull);
  });

  test('rejects empty, duplicate and unknown items', () {
    expect(_check([]), isNotNull);
    expect(
      _check(['itm_poplin_shirt', 'itm_poplin_shirt', 'itm_wool_trousers']),
      contains('repeats'),
    );
    expect(
      _check(['itm_poplin_shirt', 'itm_wool_trousers', 'itm_ghost']),
      contains('itm_ghost'),
    );
  });

  test('rejects items from different residences', () {
    expect(
      _check(['itm_poplin_shirt', 'itm_wool_trousers', 'itm_chelsea_boots']),
      contains('residences'),
    );
  });

  test('rejects two items of one category', () {
    expect(
      _check(['itm_poplin_shirt', 'itm_cashmere_crew', 'itm_wool_trousers']),
      contains('same category'),
    );
  });

  test('requires a dress xor a top and bottom', () {
    expect(_check(['itm_poplin_shirt']), contains('needs'));
    expect(
      _check(['itm_evening_dress', 'itm_poplin_shirt']),
      contains('not combined'),
    );
  });
}
