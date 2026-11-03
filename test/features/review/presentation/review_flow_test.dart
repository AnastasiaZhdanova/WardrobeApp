import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/core/router/routes.dart';
import 'package:wardrobe_app/features/review/domain/reviewed_outfit.dart';

import '../../../helpers/pump_wardrobe_app.dart';

Future<void> _requestAndOpenFirstDraft(WidgetTester tester) async {
  await tester.tap(find.text('Gallery opening in the city on Thursday'));
  await tester.tap(find.byKey(const ValueKey('request-submit')));
  await tester.pumpAndSettle();
  final draft = find.text('Cashmere crewneck & Pleated midi skirt');
  await tester.ensureVisible(draft);
  await tester.pumpAndSettle();
  await tester.tap(draft);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('draft -> swap item -> approve', (tester) async {
    final (:reviews) = await pumpWardrobeApp(tester, location: Routes.style);
    await _requestAndOpenFirstDraft(tester);

    expect(find.text('Stylist review'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Draft'), findsOneWidget);

    // Swap the skirt for the wool trousers.
    await tester.tap(find.byKey(const ValueKey('swap-itm_midi_skirt')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('swap-option-itm_wool_trousers')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('outfit-item-itm_wool_trousers')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('outfit-item-itm_midi_skirt')),
      findsNothing,
    );
    expect(find.text('Edited by stylist'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('review-approve')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, 'Approved'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-approve')), findsNothing);
    expect(find.byKey(const ValueKey('swap-itm_wool_trousers')), findsNothing);

    final approved = reviews.all.singleWhere(
      (o) => o.status == DraftStatus.approved,
    );
    expect(approved.itemIds, contains('itm_wool_trousers'));
    expect(approved.proposedItemIds, contains('itm_midi_skirt'));

    // The request screen reflects the decision on return.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, 'Approved'), findsOneWidget);
  });

  testWidgets('reject ends the review without approval', (tester) async {
    final (:reviews) = await pumpWardrobeApp(tester, location: Routes.style);
    await _requestAndOpenFirstDraft(tester);

    await tester.tap(find.byKey(const ValueKey('review-reject')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, 'Rejected'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-approve')), findsNothing);
    expect(reviews.all.where((o) => o.status == DraftStatus.approved), isEmpty);
  });
}
