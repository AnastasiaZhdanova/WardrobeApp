import '../../wardrobe/domain/wardrobe_item.dart';
import 'outfit_draft.dart';
import 'styling_request.dart';

abstract interface class StylingAgent {
  /// Proposes outfits built only from [wardrobe]. Callers must still check
  /// the output with `OutfitRules`; an implementation is never trusted.
  Future<List<OutfitDraft>> suggest(
    StylingRequest request,
    List<WardrobeItem> wardrobe,
  );
}
