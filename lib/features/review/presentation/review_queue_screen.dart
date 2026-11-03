import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/providers/review_data_providers.dart';
import '../../../shared/widgets/outfit_card.dart';
import '../../../shared/widgets/status_chip.dart';

/// Every outfit the assistant has proposed, newest first, with its status.
class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reviewQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: switch (queue) {
        AsyncData(:final value) when value.isEmpty => const Center(
          child: Text('No outfits yet. Ask for one from the wardrobe.'),
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final outfit = value[index];
            return OutfitCard(
              key: ValueKey(outfit.id),
              title: outfit.title,
              subtitle: outfit.requestText,
              itemIds: outfit.itemIds,
              trailing: StatusChip(status: outfit.status),
              onTap: () => context.push(Routes.review(outfit.id)),
            );
          },
        ),
        AsyncError() => const Center(child: Text('Could not load reviews.')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
