import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/result.dart';
import '../domain/review_repository.dart';
import '../domain/reviewed_outfit.dart';

class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ReviewedOutfit>> watchAll() =>
      (_db.select(_db.reviewedOutfits)..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm(expression: t.id),
          ]))
          .watch()
          .map((rows) => rows.map(_toDomain).toList());

  @override
  Future<Result<ReviewedOutfit>> getById(String id) async {
    try {
      final row = await (_db.select(
        _db.reviewedOutfits,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      return row == null
          ? Err(NotFoundFailure('Outfit $id not found.'))
          : Ok(_toDomain(row));
    } on Exception catch (e) {
      return Err(StorageFailure('Could not read outfit: $e'));
    }
  }

  @override
  Future<Result<void>> saveAll(List<ReviewedOutfit> outfits) async {
    try {
      await _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.reviewedOutfits,
          outfits.map(_toRow),
        ),
      );
      return const Ok(null);
    } on Exception catch (e) {
      return Err(StorageFailure('Could not save review: $e'));
    }
  }

  static ReviewedOutfitsCompanion _toRow(ReviewedOutfit o) =>
      ReviewedOutfitsCompanion.insert(
        id: o.id,
        requestText: o.requestText,
        title: o.title,
        rationale: o.rationale,
        proposedItemIds: o.proposedItemIds.join(','),
        itemIds: o.itemIds.join(','),
        status: o.status.name,
        createdAt: o.createdAt,
        decidedAt: Value(o.decidedAt),
      );

  static ReviewedOutfit _toDomain(ReviewedOutfitRow row) => ReviewedOutfit(
    id: row.id,
    requestText: row.requestText,
    title: row.title,
    rationale: row.rationale,
    proposedItemIds: row.proposedItemIds.split(','),
    itemIds: row.itemIds.split(','),
    status: DraftStatus.values.byName(row.status),
    createdAt: row.createdAt,
    decidedAt: row.decidedAt,
  );
}
