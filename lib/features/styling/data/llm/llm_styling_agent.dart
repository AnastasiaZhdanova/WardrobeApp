import 'dart:convert';

import '../../../wardrobe/domain/wardrobe_item.dart';
import '../../domain/outfit_draft.dart';
import '../../domain/styling_agent.dart';
import '../../domain/styling_request.dart';
import 'anthropic_messages_client.dart';
import 'llm_exceptions.dart';
import 'outfit_schema.dart';

const _system = '''
You are a styling assistant drafting outfits for a human stylist to review.
Build 2-3 outfits using only the wardrobe items provided, by id.
Each outfit is either a dress, or a top and a bottom; add shoes, and
outerwear or an accessory when they suit the occasion. Never use two items
of the same category, and keep every outfit within one residence.
Prefer items whose formality and seasons match the request.
The rationale is one or two sentences for the stylist, citing the occasion.''';

/// Claude-backed agent. Sends only item ids and attributes (no names,
/// brands, notes, or user identity), asks for schema-constrained JSON,
/// and retries once on a transient failure. Callers wrap it in
/// `FallbackStylingAgent` so a final failure degrades to the offline mock.
class LlmStylingAgent implements StylingAgent {
  const LlmStylingAgent(this._client, {required this.model});

  final AnthropicMessagesClient _client;
  final String model;

  static const _maxAttempts = 2;

  @override
  Future<List<OutfitDraft>> suggest(
    StylingRequest request,
    List<WardrobeItem> wardrobe,
  ) async {
    final byId = {for (final item in wardrobe) item.id: item};
    final body = buildRequestBody(request, wardrobe);

    for (var attempt = 1; ; attempt++) {
      try {
        final text = await _client.createMessage(body);
        final outfits = parseOutfits(text, byId.keys.toSet());
        return [
          for (final outfit in outfits)
            OutfitDraft(
              title: outfitTitle(outfit.itemIds.map((id) => byId[id]!)),
              rationale: outfit.rationale,
              itemIds: outfit.itemIds,
            ),
        ];
      } on LlmException catch (e) {
        if (!e.retryable || attempt == _maxAttempts) rethrow;
      }
    }
  }

  /// Exposed for tests: the exact payload, so data minimisation is checkable.
  Map<String, Object?> buildRequestBody(
    StylingRequest request,
    List<WardrobeItem> wardrobe,
  ) => {
    'model': model,
    'max_tokens': 16000,
    'system': _system,
    'output_config': {
      'effort': 'low',
      'format': {
        'type': 'json_schema',
        'schema': outfitSchema(wardrobe.map((i) => i.id)),
      },
    },
    'messages': [
      {
        'role': 'user',
        'content': jsonEncode({
          'request': request.text,
          'residence': ?request.residence?.name,
          'wardrobe': [
            for (final item in wardrobe)
              {
                'id': item.id,
                'category': item.category.name,
                'color': item.color.name,
                'seasons': [for (final s in item.seasons) s.name],
                'residence': item.residence.name,
                'formality': item.formality.name,
              },
          ],
        }),
      },
    ],
  };
}
