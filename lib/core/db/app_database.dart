import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// Wardrobe cache. Enum attributes are stored by name so the
/// schema does not depend on feature domain types; mapping happens in each
/// feature's data layer.
@DataClassName('WardrobeItemRow')
class WardrobeItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text()();
  TextColumn get category => text()();
  TextColumn get color => text()();

  /// Comma-separated season names, e.g. `spring,summer`.
  TextColumn get seasons => text()();
  TextColumn get residence => text()();
  TextColumn get formality => text()();
  TextColumn get imageAsset => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [WardrobeItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(driftDatabase(name: 'wardrobe_app'));
  ref.onDispose(db.close);
  return db;
}
