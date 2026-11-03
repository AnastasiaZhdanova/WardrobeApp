import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/core/db/app_database.dart';
import 'package:wardrobe_app/core/result.dart';
import 'package:wardrobe_app/features/review/data/drift_review_repository.dart';
import 'package:wardrobe_app/features/review/domain/reviewed_outfit.dart';

final _outfit = ReviewedOutfit(
  id: 'o1',
  requestText: 'Opera',
  title: 'Evening dress',
  rationale: 'Formal.',
  proposedItemIds: const ['itm_evening_dress', 'itm_court_heels'],
  itemIds: const ['itm_evening_dress', 'itm_court_heels'],
  status: DraftStatus.draft,
  createdAt: DateTime.utc(2026, 11, 2),
);

void main() {
  late AppDatabase db;
  late DriftReviewRepository repository;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftReviewRepository(db);
  });

  tearDown(() => db.close());

  test('round-trips an outfit', () async {
    await repository.saveAll([_outfit]);

    final result = await repository.getById('o1');

    final stored = (result as Ok<ReviewedOutfit>).value;
    expect(stored.copyWith(createdAt: _outfit.createdAt), _outfit);
    expect(stored.createdAt.isAtSameMomentAs(_outfit.createdAt), isTrue);
  });

  test('saving the same id replaces it and the stream emits', () async {
    final emissions = repository.watchAll().map(
      (all) => all.map((o) => o.status).toList(),
    );
    final expectation = expectLater(
      emissions,
      emitsThrough([DraftStatus.approved]),
    );

    await repository.saveAll([_outfit]);
    await repository.saveAll([_outfit.copyWith(status: DraftStatus.approved)]);

    await expectation;
  });

  test('missing id is NotFound', () async {
    final result = await repository.getById('nope');

    expect((result as Err).failure, isA<NotFoundFailure>());
  });
}
