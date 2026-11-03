import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/styling/data/mock_styling_agent.dart';
import 'package:wardrobe_app/features/styling/domain/outfit_rules.dart';
import 'package:wardrobe_app/features/styling/domain/styling_request.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_item.dart';

const _agent = MockStylingAgent();
final _byId = {for (final item in seedWardrobe) item.id: item};

Future<List<List<String>>> _suggest(String text, {Residence? residence}) async {
  final drafts = await _agent.suggest(
    StylingRequest(text: text, residence: residence),
    seedWardrobe,
  );
  return [for (final d in drafts) d.itemIds];
}

void main() {
  test('is deterministic', () async {
    const request = StylingRequest(text: 'Gallery opening in the city');
    final first = await _agent.suggest(request, seedWardrobe);
    final second = await _agent.suggest(request, seedWardrobe);
    expect(first, second);
  });

  test('every draft passes the outfit rules, at most three', () async {
    for (final text in [
      'Gallery opening in the city',
      'Lunch at the villa by the sea, it will be hot',
      'Cold weekend walk with the dog in the country',
      'Dinner at the opera, it will be cold',
      'anything',
    ]) {
      final outfits = await _suggest(text);
      expect(outfits, isNotEmpty, reason: text);
      expect(outfits.length, lessThanOrEqualTo(OutfitRules.maxDrafts));
      for (final ids in outfits) {
        expect(OutfitRules.violation(ids, _byId), isNull, reason: '$ids');
      }
    }
  });

  test(
    'formal cold request: evening dress with heels and coat first',
    () async {
      final outfits = await _suggest('Dinner at the opera, it will be cold');

      expect(outfits.first, [
        'itm_evening_dress',
        'itm_court_heels',
        'itm_camel_coat',
        'itm_leather_tote',
      ]);
      // Casual country knitwear is too far from "formal" to be proposed.
      expect(
        outfits.expand((ids) => ids),
        isNot(contains('itm_fisherman_knit')),
      );
    },
  );

  test('keywords pick the residence and season', () async {
    final outfits = await _suggest('Cold weekend walk with the dog');

    expect(outfits, [
      ['itm_fisherman_knit', 'itm_dark_jeans', 'itm_chelsea_boots'],
    ]);
  });

  test('explicit residence overrides keywords', () async {
    final outfits = await _suggest('Beach lunch', residence: Residence.city);

    for (final ids in outfits) {
      expect(_byId[ids.first]!.residence, Residence.city);
    }
  });

  test('no base item is reused across drafts', () async {
    final outfits = await _suggest('Gallery opening in the city');
    final bases = [
      for (final ids in outfits)
        ...ids.where((id) => _byId[id]!.category.isBase),
    ];
    expect(bases.toSet().length, bases.length);
  });

  test('empty wardrobe yields no drafts', () async {
    final drafts = await _agent.suggest(
      const StylingRequest(text: 'Dinner'),
      const [],
    );
    expect(drafts, isEmpty);
  });
}
