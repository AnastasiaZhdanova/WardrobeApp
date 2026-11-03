import '../../wardrobe/domain/wardrobe_item.dart';
import '../domain/outfit_draft.dart';
import '../domain/styling_agent.dart';
import '../domain/styling_request.dart';

/// Tries [primary]; on any exception (timeout, refusal, bad output) answers
/// with [fallback] and labels the drafts so the stylist knows their source.
class FallbackStylingAgent implements StylingAgent {
  const FallbackStylingAgent({required this.primary, required this.fallback});

  final StylingAgent primary;
  final StylingAgent fallback;

  @override
  Future<List<OutfitDraft>> suggest(
    StylingRequest request,
    List<WardrobeItem> wardrobe,
  ) async {
    try {
      return await primary.suggest(request, wardrobe);
    } on Exception {
      final drafts = await fallback.suggest(request, wardrobe);
      return [
        for (final d in drafts)
          d.copyWith(rationale: 'Offline suggestion. ${d.rationale}'),
      ];
    }
  }
}
