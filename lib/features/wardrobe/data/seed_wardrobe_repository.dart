import '../../../core/result.dart';
import '../domain/wardrobe_item.dart';
import '../domain/wardrobe_repository.dart';
import 'seed_wardrobe.dart';

/// Serves the bundled seed list from memory until local persistence exists.
class SeedWardrobeRepository implements WardrobeRepository {
  const SeedWardrobeRepository();

  @override
  Future<Result<List<WardrobeItem>>> getAll() async =>
      Ok([...seedWardrobe]..sort((a, b) => a.name.compareTo(b.name)));
}
