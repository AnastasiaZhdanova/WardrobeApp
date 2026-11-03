import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/core/result.dart';
import 'package:wardrobe_app/features/styling/domain/outfit_draft.dart';
import 'package:wardrobe_app/features/styling/domain/request_outfits.dart';
import 'package:wardrobe_app/features/styling/domain/styling_request.dart';

import '../../../fakes/fake_styling_agent.dart';
import '../../../fakes/fake_wardrobe_repository.dart';

const _valid = OutfitDraft(
  title: 'Valid',
  rationale: '',
  itemIds: ['itm_poplin_shirt', 'itm_wool_trousers'],
);
const _unknownItem = OutfitDraft(
  title: 'Hallucinated',
  rationale: '',
  itemIds: ['itm_poplin_shirt', 'itm_gold_trousers'],
);
const _mixedResidence = OutfitDraft(
  title: 'Mixed',
  rationale: '',
  itemIds: ['itm_poplin_shirt', 'itm_dark_jeans'],
);
const _request = StylingRequest(text: 'Office');

RequestOutfits _useCase(FakeStylingAgent agent) =>
    RequestOutfits(FakeWardrobeRepository(), agent);

void main() {
  test(
    'blank text is a validation failure and never reaches the agent',
    () async {
      final agent = FakeStylingAgent(
        [],
        error: Exception('must not be called'),
      );

      final result = await _useCase(agent)(const StylingRequest(text: '  '));

      expect((result as Err).failure, isA<ValidationFailure>());
    },
  );

  test('drops drafts that break the outfit rules', () async {
    final agent = FakeStylingAgent([_unknownItem, _valid, _mixedResidence]);

    final result = await _useCase(agent)(_request);

    expect((result as Ok<List<OutfitDraft>>).value, [_valid]);
  });

  test('keeps at most three drafts', () async {
    final agent = FakeStylingAgent(List.filled(5, _valid));

    final result = await _useCase(agent)(_request);

    expect((result as Ok<List<OutfitDraft>>).value, hasLength(3));
  });

  test('no valid draft is a StylingFailure', () async {
    final agent = FakeStylingAgent([_unknownItem]);

    final result = await _useCase(agent)(_request);

    expect((result as Err).failure, isA<StylingFailure>());
  });

  test('agent exception becomes a StylingFailure', () async {
    final agent = FakeStylingAgent([], error: Exception('boom'));

    final result = await _useCase(agent)(_request);

    expect((result as Err).failure, isA<StylingFailure>());
  });
}
