import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/styling/data/fallback_styling_agent.dart';
import 'package:wardrobe_app/features/styling/domain/outfit_draft.dart';
import 'package:wardrobe_app/features/styling/domain/styling_request.dart';

import '../../../fakes/fake_styling_agent.dart';

const _draft = OutfitDraft(title: 'T', rationale: 'Why.', itemIds: ['a']);
const _request = StylingRequest(text: 'Dinner');

void main() {
  test('passes primary drafts through untouched', () async {
    final agent = FallbackStylingAgent(
      primary: FakeStylingAgent([_draft]),
      fallback: FakeStylingAgent([], error: Exception('unused')),
    );

    expect(await agent.suggest(_request, const []), [_draft]);
  });

  test('uses the fallback and labels its drafts when primary fails', () async {
    final agent = FallbackStylingAgent(
      primary: FakeStylingAgent([], error: Exception('timeout')),
      fallback: FakeStylingAgent([_draft]),
    );

    final drafts = await agent.suggest(_request, const []);

    expect(drafts.single.rationale, 'Offline suggestion. Why.');
    expect(drafts.single.itemIds, _draft.itemIds);
  });
}
