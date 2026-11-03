import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/styling/data/mock_styling_agent.dart';
import 'package:wardrobe_app/features/styling/presentation/styling_providers.dart';
import 'package:wardrobe_app/features/styling/presentation/styling_request_screen.dart';
import 'package:wardrobe_app/shared/providers/review_data_providers.dart';
import 'package:wardrobe_app/shared/providers/wardrobe_data_providers.dart';

import '../../../fakes/fake_review_repository.dart';
import '../../../fakes/fake_wardrobe_repository.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wardrobeRepositoryProvider.overrideWithValue(FakeWardrobeRepository()),
        reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
        stylingAgentProvider.overrideWithValue(const MockStylingAgent()),
      ],
      child: const MaterialApp(home: StylingRequestScreen()),
    ),
  );
}

void main() {
  testWidgets('example request returns drafts marked as drafts', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(
      find.text('Cold weekend walk with the dog in the country'),
    );
    await tester.tap(find.byKey(const ValueKey('request-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Fisherman knit & Dark jeans'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Draft'), findsOneWidget);
    expect(find.textContaining('Nothing is final'), findsOneWidget);
  });

  testWidgets('empty request shows the validation message', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('request-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Describe the occasion first.'), findsOneWidget);
  });
}
