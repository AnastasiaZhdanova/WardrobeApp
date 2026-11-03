import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_message.dart';
import '../../../shared/widgets/attribute_labels.dart';
import '../../../shared/widgets/wardrobe_image.dart';
import '../domain/wardrobe_item.dart';
import 'wardrobe_providers.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(wardrobeItemProvider(itemId));
    return Scaffold(
      appBar: AppBar(),
      body: switch (item) {
        AsyncData(:final value) => _ItemDetail(item: value),
        AsyncError(:final error) => Center(child: Text(errorMessage(error))),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ItemDetail extends StatelessWidget {
  const _ItemDetail({required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'item-${item.id}',
              child: WardrobeImage(asset: item.imageAsset),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(item.name, style: text.headlineSmall),
        Text(item.brand, style: text.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(item.category.label)),
            Chip(
              avatar: CircleAvatar(backgroundColor: item.color.swatch),
              label: Text(item.color.label),
            ),
            Chip(label: Text(item.formality.label)),
            Chip(
              avatar: const Icon(Icons.home_outlined),
              label: Text(item.residence.label),
            ),
            for (final season in Season.values)
              if (item.seasons.contains(season))
                Chip(label: Text(season.label)),
          ],
        ),
        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(item.notes, style: text.bodyMedium),
        ],
      ],
    );
  }
}
