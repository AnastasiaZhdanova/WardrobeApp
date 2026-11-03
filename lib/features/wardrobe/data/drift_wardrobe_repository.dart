import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/result.dart';
import '../domain/wardrobe_item.dart';
import '../domain/wardrobe_repository.dart';
import 'seed_wardrobe.dart';

/// Cache-first repository: reads always come from drift. An empty cache is
/// filled once from [seed], which plays the role of the remote source.
class DriftWardrobeRepository implements WardrobeRepository {
  DriftWardrobeRepository(this._db, {this.seed = seedWardrobe});

  final AppDatabase _db;
  final List<WardrobeItem> seed;
  Future<void>? _seeding;

  @override
  Future<Result<List<WardrobeItem>>> getAll() => _guard(() async {
    final rows = await (_db.select(
      _db.wardrobeItems,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    return rows.map(_toDomain).toList();
  });

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      // Concurrent first reads share one seeding pass.
      await (_seeding ??= _seedIfEmpty());
      return Ok(await body());
    } on Exception catch (e) {
      // Allow the next call to retry seeding after a failure.
      _seeding = null;
      return Err(StorageFailure('Wardrobe cache unavailable: $e'));
    }
  }

  Future<void> _seedIfEmpty() async {
    final count = await _db.wardrobeItems.count().getSingle();
    if (count > 0) return;
    await _db.batch(
      (batch) => batch.insertAll(_db.wardrobeItems, seed.map(_toRow)),
    );
  }

  static WardrobeItemsCompanion _toRow(WardrobeItem item) =>
      WardrobeItemsCompanion.insert(
        id: item.id,
        name: item.name,
        brand: item.brand,
        category: item.category.name,
        color: item.color.name,
        seasons: item.seasons.map((s) => s.name).join(','),
        residence: item.residence.name,
        formality: item.formality.name,
        imageAsset: item.imageAsset,
        notes: Value(item.notes),
      );

  /// Throws [ArgumentError] on an unknown enum name, which [_guard] does not
  /// catch: a corrupt cache row is a programming error, not a user error.
  static WardrobeItem _toDomain(WardrobeItemRow row) => WardrobeItem(
    id: row.id,
    name: row.name,
    brand: row.brand,
    category: ItemCategory.values.byName(row.category),
    color: ColorFamily.values.byName(row.color),
    seasons: row.seasons.split(',').map(Season.values.byName).toSet(),
    residence: Residence.values.byName(row.residence),
    formality: Formality.values.byName(row.formality),
    imageAsset: row.imageAsset,
    notes: row.notes,
  );
}
