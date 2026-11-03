import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error_message.dart';
import '../../../core/router/routes.dart';
import '../../../shared/widgets/wardrobe_image.dart';
import '../domain/wardrobe_item.dart';
import 'filter_bar.dart';
import 'wardrobe_providers.dart';

class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredWardrobeProvider);
    final hasFilter = !ref.watch(
      wardrobeFilterControllerProvider.select((f) => f.isEmpty),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        actions: [
          if (hasFilter)
            TextButton(
              onPressed: ref
                  .read(wardrobeFilterControllerProvider.notifier)
                  .clear,
              child: const Text('Clear'),
            ),
          IconButton(
            tooltip: 'Review queue',
            onPressed: () => context.push(Routes.reviewQueue),
            icon: const Icon(Icons.fact_check_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.style),
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('Style me'),
      ),
      body: Column(
        children: [
          const FilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: switch (items) {
              AsyncData(:final value) when value.isEmpty => const Center(
                child: Text('No items match these filters.'),
              ),
              AsyncData(:final value) => _ItemGrid(items: value),
              AsyncError(:final error) => Center(
                child: Text(errorMessage(error)),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});

  final List<WardrobeItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(key: ValueKey(item.id), item: item);
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, super.key});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card.filled(
      child: InkWell(
        onTap: () => context.push(Routes.item(item.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'item-${item.id}',
                child: WardrobeImage(asset: item.imageAsset),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(item.brand, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
