import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/styling/domain/outfit_draft.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';

final _byId = {for (final item in seedWardrobe) item.id: item};

String _title(List<String> ids) => outfitTitle(ids.map((id) => _byId[id]!));

void main() {
  test('names the base garments in outfit order, ignoring extras', () {
    expect(
      _title(['itm_poplin_shirt', 'itm_leather_loafers', 'itm_wool_trousers']),
      'Poplin shirt & Wool trousers',
    );
  });

  test('a dress is its own title', () {
    expect(_title(['itm_evening_dress', 'itm_court_heels']), 'Evening dress');
  });
}
