import 'package:wardrobe_app/features/styling/domain/outfit_draft.dart';
import 'package:wardrobe_app/features/styling/domain/styling_agent.dart';
import 'package:wardrobe_app/features/styling/domain/styling_request.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_item.dart';

/// Returns canned drafts, or throws [error] when set.
class FakeStylingAgent implements StylingAgent {
  FakeStylingAgent(this.drafts, {this.error});

  final List<OutfitDraft> drafts;
  final Exception? error;

  @override
  Future<List<OutfitDraft>> suggest(
    StylingRequest request,
    List<WardrobeItem> wardrobe,
  ) async {
    if (error case final error?) throw error;
    return drafts;
  }
}
