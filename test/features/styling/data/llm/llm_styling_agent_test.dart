import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wardrobe_app/features/styling/data/llm/anthropic_messages_client.dart';
import 'package:wardrobe_app/features/styling/data/llm/llm_exceptions.dart';
import 'package:wardrobe_app/features/styling/data/llm/llm_styling_agent.dart';
import 'package:wardrobe_app/features/styling/domain/styling_request.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_item.dart';

const _request = StylingRequest(
  text: 'Gallery opening',
  residence: Residence.city,
);

http.Response _text(String text) => http.Response(
  jsonEncode({
    'stop_reason': 'end_turn',
    'content': [
      {'type': 'text', 'text': text},
    ],
  }),
  200,
);

const _valid =
    '{"outfits":[{"item_ids":["itm_poplin_shirt","itm_wool_trousers"],'
    '"rationale":"Smart for a gallery."}]}';

/// Replies with [responses] in order and counts calls.
({LlmStylingAgent agent, int Function() calls}) _agent(
  List<http.Response> responses,
) {
  var calls = 0;
  final client = MockClient((_) async => responses[calls++]);
  return (
    agent: LlmStylingAgent(
      AnthropicMessagesClient(apiKey: 'k', httpClient: client),
      model: 'claude-sonnet-5-5',
    ),
    calls: () => calls,
  );
}

void main() {
  test('maps the model output to drafts with locally built titles', () async {
    final (:agent, :calls) = _agent([_text(_valid)]);

    final drafts = await agent.suggest(_request, seedWardrobe);

    expect(drafts.single.title, 'Poplin shirt & Wool trousers');
    expect(drafts.single.itemIds, ['itm_poplin_shirt', 'itm_wool_trousers']);
    expect(drafts.single.rationale, 'Smart for a gallery.');
    expect(calls(), 1);
  });

  test('payload holds ids and attributes only', () {
    final (:agent, calls: _) = _agent([]);

    final body = agent.buildRequestBody(_request, seedWardrobe);
    final messages = body['messages']! as List;
    final payload = (messages.single as Map)['content']! as String;
    final items = (jsonDecode(payload) as Map)['wardrobe'] as List;

    expect((items.first as Map).keys, {
      'id',
      'category',
      'color',
      'seasons',
      'residence',
      'formality',
    });
    for (final item in seedWardrobe) {
      expect(payload, isNot(contains(item.brand)));
      expect(payload, isNot(contains(item.name)));
      if (item.notes.isNotEmpty) expect(payload, isNot(contains(item.notes)));
    }
    expect(body, isNot(contains('temperature')));
  });

  test('retries once after malformed output', () async {
    final (:agent, :calls) = _agent([_text('not json'), _text(_valid)]);

    final drafts = await agent.suggest(_request, seedWardrobe);

    expect(drafts, hasLength(1));
    expect(calls(), 2);
  });

  test('gives up after the second failure', () async {
    final (:agent, :calls) = _agent([
      http.Response('', 529),
      http.Response('', 529),
    ]);

    await expectLater(
      agent.suggest(_request, seedWardrobe),
      throwsA(isA<LlmHttpException>()),
    );
    expect(calls(), 2);
  });

  test('does not retry a non-retryable error', () async {
    final (:agent, :calls) = _agent([http.Response('', 401)]);

    await expectLater(
      agent.suggest(_request, seedWardrobe),
      throwsA(isA<LlmHttpException>()),
    );
    expect(calls(), 1);
  });

  test('a hallucinated id rejects the response', () async {
    const hallucinated =
        '{"outfits":[{"item_ids":["itm_poplin_shirt","itm_gold_trousers"],'
        '"rationale":"x"}]}';
    final (:agent, calls: _) = _agent([
      _text(hallucinated),
      _text(hallucinated),
    ]);

    await expectLater(
      agent.suggest(_request, seedWardrobe),
      throwsA(isA<LlmFormatException>()),
    );
  });
}
