import 'dart:convert';

import 'llm_exceptions.dart';

/// One outfit as the model returns it. Titles are built locally from item
/// names, so the model never needs to see them.
typedef LlmOutfit = ({List<String> itemIds, String rationale});

/// JSON schema sent as `output_config.format`. `item_ids` is an enum of the
/// ids actually in the wardrobe, so the API constrains generation to real
/// items; [parseOutfits] still re-checks everything.
Map<String, Object?> outfitSchema(Iterable<String> knownIds) => {
  'type': 'object',
  'additionalProperties': false,
  'required': ['outfits'],
  'properties': {
    'outfits': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['item_ids', 'rationale'],
        'properties': {
          'item_ids': {
            'type': 'array',
            'items': {'type': 'string', 'enum': knownIds.toList()},
          },
          'rationale': {'type': 'string'},
        },
      },
    },
  },
};

/// Validates [text] against [outfitSchema] by hand. Any deviation, including
/// an unknown item id, rejects the whole response: a model that invents one
/// item is not trusted for the others.
List<LlmOutfit> parseOutfits(String text, Set<String> knownIds) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const LlmFormatException('Output is not JSON.');
  }
  if (json case {
    'outfits': final List<Object?> outfits,
  } when (json as Map).length == 1) {
    if (outfits.isEmpty) throw const LlmFormatException('No outfits.');
    return [for (final outfit in outfits) _parseOutfit(outfit, knownIds)];
  }
  throw const LlmFormatException('Expected exactly {"outfits": [...]}.');
}

LlmOutfit _parseOutfit(Object? outfit, Set<String> knownIds) {
  if (outfit
      case {
            'item_ids': final List<Object?> ids,
            'rationale': final String rationale,
          } &&
          Map(length: 2)) {
    final itemIds = <String>[];
    for (final id in ids) {
      if (id is! String) {
        throw const LlmFormatException('Item id is not a string.');
      }
      if (!knownIds.contains(id)) {
        throw LlmFormatException('Unknown item id "$id".');
      }
      itemIds.add(id);
    }
    return (itemIds: itemIds, rationale: rationale.trim());
  }
  throw const LlmFormatException('Outfit must have only item_ids, rationale.');
}
