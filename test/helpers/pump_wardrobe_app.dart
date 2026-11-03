import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/app.dart';
import 'package:wardrobe_app/app_router.dart';
import 'package:wardrobe_app/features/app_lock/presentation/app_lock_controller.dart';
import 'package:wardrobe_app/features/styling/data/mock_styling_agent.dart';
import 'package:wardrobe_app/features/styling/presentation/styling_providers.dart';
import 'package:wardrobe_app/shared/providers/review_data_providers.dart';
import 'package:wardrobe_app/shared/providers/wardrobe_data_providers.dart';

import '../fakes/fake_device_auth.dart';
import '../fakes/fake_review_repository.dart';
import '../fakes/fake_wardrobe_repository.dart';

/// The fakes behind a [pumpWardrobeApp] run, for assertions on stored state.
typedef WardrobeAppFakes = ({FakeReviewRepository reviews});

/// Pumps the whole app on an iPhone-sized screen with every boundary faked:
/// seed wardrobe, in-memory reviews, the deterministic mock agent, and a
/// device-auth prompt that always succeeds. Starts at [location].
Future<WardrobeAppFakes> pumpWardrobeApp(
  WidgetTester tester, {
  String location = '/',
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final reviews = FakeReviewRepository();
  final container = ProviderContainer(
    overrides: [
      wardrobeRepositoryProvider.overrideWithValue(FakeWardrobeRepository()),
      reviewRepositoryProvider.overrideWithValue(reviews),
      stylingAgentProvider.overrideWithValue(const MockStylingAgent()),
      deviceAuthProvider.overrideWithValue(FakeDeviceAuth.success()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WardrobeApp()),
  );
  container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
  return (reviews: reviews);
}
