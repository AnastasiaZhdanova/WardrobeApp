import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_wardrobe_app.dart';

/// Filter rows scroll horizontally, so a chip may start off-screen.
Future<void> _tapChip(WidgetTester tester, String key) async {
  final chip = find.byKey(ValueKey(key));
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('residence filter narrows the grid and can be cleared', (
    tester,
  ) async {
    await pumpWardrobeApp(tester);
    expect(find.text('Cashmere crewneck'), findsOneWidget);

    await _tapChip(tester, 'filter-residence-coast');

    expect(find.text('Linen shirt'), findsOneWidget);
    expect(find.text('Cashmere crewneck'), findsNothing);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Cashmere crewneck'), findsOneWidget);
  });

  testWidgets('combined filters with no match show an empty state', (
    tester,
  ) async {
    await pumpWardrobeApp(tester);

    await _tapChip(tester, 'filter-residence-coast');
    await _tapChip(tester, 'filter-season-winter');

    expect(find.text('No items match these filters.'), findsOneWidget);
  });

  testWidgets('tapping an item opens its detail screen', (tester) async {
    await pumpWardrobeApp(tester);

    await tester.tap(find.text('Cashmere crewneck'));
    await tester.pumpAndSettle();

    expect(find.text('Maison Arden'), findsOneWidget);
    expect(find.text('City flat'), findsOneWidget);
    expect(find.text('Winter'), findsOneWidget);
  });
}
