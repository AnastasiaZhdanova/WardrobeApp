import '../../../core/result.dart';
import 'reviewed_outfit.dart';

abstract interface class ReviewRepository {
  /// Newest first. Emits again after every save.
  Stream<List<ReviewedOutfit>> watchAll();

  Future<Result<ReviewedOutfit>> getById(String id);

  /// Inserts or replaces by id.
  Future<Result<void>> saveAll(List<ReviewedOutfit> outfits);
}
