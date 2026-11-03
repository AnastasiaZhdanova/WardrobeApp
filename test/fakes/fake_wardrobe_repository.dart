import 'package:wardrobe_app/core/result.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_item.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_repository.dart';

class FakeWardrobeRepository implements WardrobeRepository {
  FakeWardrobeRepository([this.items = seedWardrobe]);

  final List<WardrobeItem> items;

  @override
  Future<Result<List<WardrobeItem>>> getAll() async => Ok(items);
}
