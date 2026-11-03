import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/router/routes.dart';
import 'features/review/presentation/review_queue_screen.dart';
import 'features/review/presentation/review_screen.dart';
import 'features/styling/presentation/styling_request_screen.dart';
import 'features/wardrobe/presentation/item_detail_screen.dart';
import 'features/wardrobe/presentation/wardrobe_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: Routes.wardrobe,
        builder: (context, state) => const WardrobeScreen(),
        routes: [
          GoRoute(
            path: 'item/:id',
            builder: (context, state) =>
                ItemDetailScreen(itemId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.style,
        builder: (context, state) => const StylingRequestScreen(),
      ),
      GoRoute(
        path: Routes.reviewQueue,
        builder: (context, state) => const ReviewQueueScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ReviewScreen(outfitId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
