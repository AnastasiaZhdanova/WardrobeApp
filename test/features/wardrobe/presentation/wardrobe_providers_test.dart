import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/core/result.dart';
import 'package:wardrobe_app/features/wardrobe/domain/wardrobe_item.dart';
import 'package:wardrobe_app/features/wardrobe/presentation/wardrobe_providers.dart';
import 'package:wardrobe_app/shared/providers/wardrobe_data_providers.dart';

import '../../../fakes/fake_wardrobe_repository.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        wardrobeRepositoryProvider.overrideWithValue(FakeWardrobeRepository()),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<AsyncValue<WardrobeItem>> itemOnceLoaded(String id) async {
    // Keep the lookup alive while the wardrobe loads.
    final subscription = container.listen(wardrobeItemProvider(id), (_, _) {});
    addTearDown(subscription.close);
    await container.read(wardrobeByIdProvider.future);
    return container.read(wardrobeItemProvider(id));
  }

  test('item comes from the loaded wardrobe', () async {
    final item = await itemOnceLoaded('itm_camel_coat');

    expect(item.requireValue.name, 'Camel coat');
  });

  test('unknown id is a NotFoundFailure', () async {
    final item = await itemOnceLoaded('missing');

    expect(item.error, isA<NotFoundFailure>());
  });
}
