import '../../../core/result.dart';
import 'wardrobe_item.dart';

abstract interface class WardrobeRepository {
  Future<Result<List<WardrobeItem>>> getAll();
}
