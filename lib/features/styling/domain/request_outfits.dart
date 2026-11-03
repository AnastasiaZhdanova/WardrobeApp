import '../../../core/result.dart';
import '../../wardrobe/domain/wardrobe_item.dart';
import '../../wardrobe/domain/wardrobe_repository.dart';
import 'outfit_draft.dart';
import 'outfit_rules.dart';
import 'styling_agent.dart';
import 'styling_request.dart';

/// Asks the agent for drafts and keeps only those that pass [OutfitRules].
class RequestOutfits {
  const RequestOutfits(this._wardrobe, this._agent);

  final WardrobeRepository _wardrobe;
  final StylingAgent _agent;

  Future<Result<List<OutfitDraft>>> call(StylingRequest request) async {
    if (request.text.trim().isEmpty) {
      return const Err(ValidationFailure('Describe the occasion first.'));
    }
    final List<WardrobeItem> items;
    switch (await _wardrobe.getAll()) {
      case Ok(:final value):
        items = value;
      case Err(:final failure):
        return Err(failure);
    }

    final List<OutfitDraft> drafts;
    try {
      drafts = await _agent.suggest(request, items);
    } on Exception {
      return const Err(StylingFailure('The styling assistant is unavailable.'));
    }

    final byId = {for (final item in items) item.id: item};
    final valid = drafts
        .where((d) => OutfitRules.violation(d.itemIds, byId) == null)
        .take(OutfitRules.maxDrafts)
        .toList();
    if (valid.isEmpty) {
      return const Err(
        StylingFailure('No outfit fits that request in this wardrobe.'),
      );
    }
    return Ok(valid);
  }
}
