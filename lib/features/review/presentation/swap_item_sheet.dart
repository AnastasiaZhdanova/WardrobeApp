import 'package:flutter/material.dart';

import '../../../shared/widgets/wardrobe_image.dart';
import '../../wardrobe/domain/wardrobe_item.dart';

/// Lets the stylist pick a replacement. Pops with the chosen item id.
class SwapItemSheet extends StatelessWidget {
  const SwapItemSheet({
    required this.current,
    required this.options,
    super.key,
  });

  final WardrobeItem current;
  final List<WardrobeItem> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Replace ${current.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final item in options)
            ListTile(
              key: ValueKey('swap-option-${item.id}'),
              leading: SizedBox.square(
                dimension: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: WardrobeImage(asset: item.imageAsset),
                ),
              ),
              title: Text(item.name),
              subtitle: Text(item.brand),
              onTap: () => Navigator.of(context).pop(item.id),
            ),
        ],
      ),
    );
  }
}
