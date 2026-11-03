import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/app.dart';
import 'package:wardrobe_app/app_router.dart';
import 'package:wardrobe_app/shared/providers/wardrobe_data_providers.dart';

import '../fakes/fake_wardrobe_repository.dart';

/// Pumps the whole app on an iPhone-sized screen with the wardrobe faked.
/// Starts at [location].
Future<void> pumpWardrobeApp(
  WidgetTester tester, {
  String location = '/',
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      wardrobeRepositoryProvider.overrideWithValue(FakeWardrobeRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WardrobeApp()),
  );
  container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}
