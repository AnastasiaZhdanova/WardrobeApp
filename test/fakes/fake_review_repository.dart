import 'dart:async';

import 'package:wardrobe_app/core/result.dart';
import 'package:wardrobe_app/features/review/domain/review_repository.dart';
import 'package:wardrobe_app/features/review/domain/reviewed_outfit.dart';

/// In-memory repository. Avoids drift's stream timers in widget tests.
class FakeReviewRepository implements ReviewRepository {
  final _outfits = <String, ReviewedOutfit>{};
  final _changes = StreamController<void>.broadcast();

  List<ReviewedOutfit> get all => _outfits.values.toList().reversed.toList();

  @override
  Stream<List<ReviewedOutfit>> watchAll() async* {
    yield all;
    await for (final _ in _changes.stream) {
      yield all;
    }
  }

  @override
  Future<Result<ReviewedOutfit>> getById(String id) async {
    final outfit = _outfits[id];
    return outfit == null
        ? Err(NotFoundFailure('Outfit $id not found.'))
        : Ok(outfit);
  }

  @override
  Future<Result<void>> saveAll(List<ReviewedOutfit> outfits) async {
    for (final outfit in outfits) {
      _outfits[outfit.id] = outfit;
    }
    _changes.add(null);
    return const Ok(null);
  }
}
