import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/wardrobe/domain/wardrobe_item.dart';
import '../../features/wardrobe/domain/wardrobe_repository.dart';

part 'wardrobe_data_providers.g.dart';

/// Bound to a concrete implementation in the composition root (`main.dart`)
/// and overridden with fakes in tests, so presentation only knows the
/// domain interface.
@Riverpod(keepAlive: true)
WardrobeRepository wardrobeRepository(Ref ref) =>
    throw UnimplementedError('Override wardrobeRepositoryProvider.');

@riverpod
Future<List<WardrobeItem>> wardrobeItems(Ref ref) async =>
    (await ref.watch(wardrobeRepositoryProvider).getAll()).valueOrThrow;

@riverpod
Future<Map<String, WardrobeItem>> wardrobeById(Ref ref) async => {
  for (final item in await ref.watch(wardrobeItemsProvider.future))
    item.id: item,
};
