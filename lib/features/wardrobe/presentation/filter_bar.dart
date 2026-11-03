import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/attribute_labels.dart';
import '../domain/wardrobe_item.dart';
import 'wardrobe_providers.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(wardrobeFilterControllerProvider);
    final controller = ref.read(wardrobeFilterControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          children: [
            for (final residence in Residence.values)
              ChoiceChip(
                key: ValueKey('filter-residence-${residence.name}'),
                label: Text(residence.label),
                selected: filter.residence == residence,
                onSelected: (_) => controller.toggleResidence(residence),
              ),
          ],
        ),
        _ChipRow(
          children: [
            for (final season in Season.values)
              ChoiceChip(
                key: ValueKey('filter-season-${season.name}'),
                label: Text(season.label),
                selected: filter.season == season,
                onSelected: (_) => controller.toggleSeason(season),
              ),
          ],
        ),
        _ChipRow(
          children: [
            for (final color in ColorFamily.values)
              ChoiceChip(
                key: ValueKey('filter-color-${color.name}'),
                avatar: CircleAvatar(backgroundColor: color.swatch),
                label: Text(color.label),
                selected: filter.color == color,
                onSelected: (_) => controller.toggleColor(color),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(spacing: 8, children: children),
    );
  }
}
