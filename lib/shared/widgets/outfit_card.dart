import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/wardrobe_data_providers.dart';
import 'wardrobe_image.dart';

/// Thumbnails, title and one line of context for an outfit. [trailing]
/// carries the status badge or actions of the screen that hosts it.
class OutfitCard extends ConsumerWidget {
  const OutfitCard({
    required this.title,
    required this.subtitle,
    required this.itemIds,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;

  /// The assistant's rationale, or the client's request, depending on host.
  final String subtitle;
  final List<String> itemIds;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byId = ref.watch(wardrobeByIdProvider).value ?? const {};
    final text = Theme.of(context).textTheme;
    return Card.outlined(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              SizedBox(
                height: 88,
                child: Row(
                  spacing: 6,
                  children: [
                    for (final id in itemIds)
                      if (byId[id] case final item?)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Tooltip(
                              message: item.name,
                              child: WardrobeImage(asset: item.imageAsset),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(child: Text(title, style: text.titleMedium)),
                  ?trailing,
                ],
              ),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
