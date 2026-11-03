import '../../wardrobe/domain/wardrobe_item.dart';
import '../domain/outfit_draft.dart';
import '../domain/outfit_rules.dart';
import '../domain/styling_agent.dart';
import '../domain/styling_request.dart';

/// Deterministic, offline agent: keyword rules pick a formality, season and
/// residence, then outfits are scored and ties broken by item id. The same
/// request and wardrobe always produce the same drafts.
class MockStylingAgent implements StylingAgent {
  const MockStylingAgent();

  @override
  Future<List<OutfitDraft>> suggest(
    StylingRequest request,
    List<WardrobeItem> wardrobe,
  ) async {
    final intent = _Intent.parse(request);
    final options = <_Option>[
      for (final residence in Residence.values)
        if (intent.residence == null || intent.residence == residence)
          ..._optionsFor(
            wardrobe
                .where(
                  (i) =>
                      i.residence == residence &&
                      (intent.season == null ||
                          i.seasons.contains(intent.season)),
                )
                .toList(),
            intent,
          ),
    ]..sort();

    // Greedy pick: no top, bottom or dress appears in two drafts.
    final usedBase = <String>{};
    final drafts = <OutfitDraft>[];
    for (final option in options) {
      if (option.base.any((i) => usedBase.contains(i.id))) continue;
      usedBase.addAll(option.base.map((i) => i.id));
      drafts.add(option.toDraft(intent));
      if (drafts.length == OutfitRules.maxDrafts) break;
    }
    return drafts;
  }

  List<_Option> _optionsFor(List<WardrobeItem> pool, _Intent intent) {
    List<WardrobeItem> of(ItemCategory c) =>
        pool.where((i) => i.category == c).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    final bases = <List<WardrobeItem>>[
      for (final dress in of(ItemCategory.dress)) [dress],
      for (final top in of(ItemCategory.top))
        for (final bottom in of(ItemCategory.bottom)) [top, bottom],
    ].where((base) => base.every(intent.fits)).toList();
    final shoes = _best(of(ItemCategory.shoes), intent);
    final outerwear = intent.wantsOuterwear
        ? _best(of(ItemCategory.outerwear), intent)
        : null;
    final accessory = _best(of(ItemCategory.accessory), intent);

    return [
      for (final base in bases)
        _Option(
          base: base,
          extras: [?shoes, ?outerwear, ?accessory],
          score: _mean([...base, ?shoes], intent),
        ),
    ];
  }

  /// Best-scoring item that [_Intent.fits], or `null`.
  WardrobeItem? _best(List<WardrobeItem> items, _Intent intent) {
    WardrobeItem? best;
    for (final item in items) {
      if (!intent.fits(item)) continue;
      if (best == null || intent.score(item) > intent.score(best)) best = item;
    }
    return best;
  }

  double _mean(List<WardrobeItem> items, _Intent intent) =>
      items.map(intent.score).reduce((a, b) => a + b) / items.length;
}

class _Option implements Comparable<_Option> {
  _Option({required this.base, required this.extras, required this.score});

  final List<WardrobeItem> base;
  final List<WardrobeItem> extras;
  final double score;

  String get _key => base.map((i) => i.id).join('+');

  @override
  int compareTo(_Option other) {
    final byScore = other.score.compareTo(score);
    return byScore != 0 ? byScore : _key.compareTo(other._key);
  }

  OutfitDraft toDraft(_Intent intent) {
    final residence = base.first.residence.name;
    final withExtras = extras.isEmpty
        ? ''
        : ', with ${extras.map((i) => i.name.toLowerCase()).join(', ')}';
    final look =
        'A ${intent.formality.name} look from the $residence wardrobe'
        '$withExtras.';
    final reasons = intent.matched.isEmpty
        ? 'No occasion keywords found, so this defaults to smart.'
        : 'Picked up: ${intent.matched.join(', ')}.';
    return OutfitDraft(
      title: outfitTitle(base),
      rationale: '$look $reasons',
      itemIds: [
        for (final item in [...base, ...extras]) item.id,
      ],
    );
  }
}

/// What the mock "understood" from the request, plus the words that drove it
/// so the rationale can explain itself.
class _Intent {
  _Intent({
    required this.formality,
    required this.season,
    required this.residence,
    required this.color,
    required this.matched,
  });

  factory _Intent.parse(StylingRequest request) {
    final words = request.text.toLowerCase().split(RegExp(r'[^a-z]+')).toSet();
    final matched = <String>[];

    T? pick<T>(Map<T, Set<String>> table) {
      T? winner;
      var winnerHits = 0;
      for (final MapEntry(:key, :value) in table.entries) {
        final hits = value.where(words.contains).toList();
        if (hits.length > winnerHits) {
          winner = key;
          winnerHits = hits.length;
        }
      }
      if (winner != null) matched.addAll(table[winner]!.where(words.contains));
      return winner;
    }

    final formality = pick(_formalityWords) ?? Formality.smart;
    final season = pick(_seasonWords);
    final residence = request.residence ?? pick(_residenceWords);
    final color = pick({
      for (final c in ColorFamily.values) c: {c.name},
    });
    return _Intent(
      formality: formality,
      season: season,
      residence: residence,
      color: color,
      matched: matched,
    );
  }

  final Formality formality;
  final Season? season;
  final Residence? residence;
  final ColorFamily? color;
  final List<String> matched;

  bool get wantsOuterwear =>
      season == Season.autumn ||
      season == Season.winter ||
      formality == Formality.formal;

  /// At most one formality step away from what the occasion asks for.
  bool fits(WardrobeItem item) =>
      (item.formality.index - formality.index).abs() <= 1;

  /// Higher is better: closeness in formality dominates, colour breaks ties.
  double score(WardrobeItem item) =>
      -2.0 * (item.formality.index - formality.index).abs() +
      (item.color == color ? 1 : 0);
}

const _formalityWords = {
  Formality.formal: {
    'dinner',
    'gala',
    'evening',
    'wedding',
    'opera',
    'party',
    'cocktail',
    'theatre',
  },
  Formality.smart: {
    'office',
    'meeting',
    'work',
    'lunch',
    'gallery',
    'business',
    'conference',
    'opening',
  },
  Formality.casual: {
    'beach',
    'weekend',
    'walk',
    'picnic',
    'garden',
    'holiday',
    'brunch',
    'relaxed',
    'travel',
  },
};

const _seasonWords = {
  Season.spring: {'spring'},
  Season.summer: {'summer', 'hot', 'warm', 'sunny'},
  Season.autumn: {'autumn', 'fall'},
  Season.winter: {'winter', 'cold', 'snow', 'freezing'},
};

const _residenceWords = {
  Residence.city: {'city', 'town', 'flat', 'apartment'},
  Residence.country: {'country', 'countryside', 'farm', 'cottage', 'dog'},
  Residence.coast: {'coast', 'beach', 'sea', 'seaside', 'villa', 'yacht'},
};
