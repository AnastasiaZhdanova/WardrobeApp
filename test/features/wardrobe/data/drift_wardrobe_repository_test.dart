import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/core/db/app_database.dart';
import 'package:wardrobe_app/core/result.dart';
import 'package:wardrobe_app/features/wardrobe/data/drift_wardrobe_repository.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_item.dart';

void main() {
  late AppDatabase db;
  late DriftWardrobeRepository repository;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftWardrobeRepository(db);
  });

  tearDown(() => db.close());

  test('first read seeds the cache and returns items sorted by name', () async {
    final result = await repository.getAll();

    final items = (result as Ok<List<WardrobeItem>>).value;
    expect(items, hasLength(seedWardrobe.length));
    final names = [for (final item in items) item.name];
    expect(names, [...names]..sort());
  });

  test('round-trips every attribute through the cache', () async {
    final result = await repository.getAll();

    final items = (result as Ok<List<WardrobeItem>>).value;
    expect(items.toSet(), seedWardrobe.toSet());
  });

  test('concurrent first reads seed only once', () async {
    final results = await Future.wait([
      repository.getAll(),
      repository.getAll(),
      repository.getAll(),
    ]);

    expect(results, everyElement(isA<Ok<Object?>>()));
    expect(await db.wardrobeItems.count().getSingle(), seedWardrobe.length);
  });

  test('a second repository reuses the existing cache', () async {
    await repository.getAll();
    final second = DriftWardrobeRepository(db, seed: const []);

    final result = await second.getAll();

    expect((result as Ok).value, hasLength(seedWardrobe.length));
  });
}
