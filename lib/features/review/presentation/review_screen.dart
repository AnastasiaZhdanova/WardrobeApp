import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_message.dart';
import '../../../shared/providers/review_data_providers.dart';
import '../../../shared/providers/wardrobe_data_providers.dart';
import '../../../shared/widgets/attribute_labels.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/wardrobe_image.dart';
import '../../wardrobe/domain/wardrobe_item.dart';
import '../domain/reviewed_outfit.dart';
import '../domain/stylist_review.dart';
import 'review_providers.dart';
import 'swap_item_sheet.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({required this.outfitId, super.key});

  final String outfitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(reviewActionsProvider(outfitId), (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
    });
    final outfit = ref.watch(reviewedOutfitProvider(outfitId));
    final wardrobe = ref.watch(wardrobeByIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stylist review')),
      body: switch ((outfit, wardrobe)) {
        (AsyncData(value: final o?), AsyncData(value: final w)) => _ReviewBody(
          outfit: o,
          wardrobe: w,
        ),
        (AsyncData(value: null), _) => const Center(
          child: Text('This outfit no longer exists.'),
        ),
        (AsyncError(), _) || (_, AsyncError()) => const Center(
          child: Text('Could not load this outfit.'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (outfit) {
        AsyncData(value: ReviewedOutfit(status: DraftStatus.draft)) =>
          _DecisionBar(outfitId: outfitId),
        _ => null,
      },
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.outfit, required this.wardrobe});

  final ReviewedOutfit outfit;
  final Map<String, WardrobeItem> wardrobe;

  Future<void> _swap(
    BuildContext context,
    WidgetRef ref,
    WardrobeItem current,
    List<WardrobeItem> options,
  ) async {
    final to = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SwapItemSheet(current: current, options: options),
    );
    if (to == null) return;
    await ref
        .read(reviewActionsProvider(outfit.id).notifier)
        .swap(from: current.id, to: to);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final isDraft = outfit.status == DraftStatus.draft;
    final busy = ref.watch(reviewActionsProvider(outfit.id)).isLoading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text(outfit.title, style: text.titleLarge)),
            StatusChip(status: outfit.status),
          ],
        ),
        const SizedBox(height: 12),
        _Labeled(label: 'Client asked', value: '"${outfit.requestText}"'),
        _Labeled(label: 'Assistant reasoning', value: outfit.rationale),
        if (outfit.isEditedByStylist)
          _Labeled(
            label: 'Edited by stylist',
            value: 'Originally proposed: ${_names(outfit.proposedItemIds)}',
          ),
        const SizedBox(height: 8),
        for (final id in outfit.itemIds)
          if (wardrobe[id] case final item?)
            _ItemRow(
              item: item,
              showSwap: isDraft,
              onSwap: isDraft && !busy ? _swapAction(context, ref, item) : null,
            ),
      ],
    );
  }

  String _names(List<String> ids) =>
      ids.map((id) => wardrobe[id]?.name ?? id).join(', ');

  /// `null` (button disabled) when nothing in this residence can replace it.
  VoidCallback? _swapAction(
    BuildContext context,
    WidgetRef ref,
    WardrobeItem item,
  ) {
    final options = swapOptions(outfit, item.id, wardrobe);
    if (options.isEmpty) return null;
    return () => _swap(context, ref, item, options);
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onSwap,
    required this.showSwap,
  });

  final WardrobeItem item;
  final VoidCallback? onSwap;
  final bool showSwap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('outfit-item-${item.id}'),
      contentPadding: EdgeInsets.zero,
      leading: SizedBox.square(
        dimension: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: WardrobeImage(asset: item.imageAsset),
        ),
      ),
      title: Text(item.name),
      subtitle: Text('${item.category.label} · ${item.brand}'),
      trailing: showSwap
          ? IconButton(
              key: ValueKey('swap-${item.id}'),
              tooltip: onSwap == null
                  ? 'No alternative in this residence'
                  : 'Swap item',
              onPressed: onSwap,
              icon: const Icon(Icons.swap_horiz),
            )
          : null,
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelMedium),
          Text(value, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _DecisionBar extends ConsumerWidget {
  const _DecisionBar({required this.outfitId});

  final String outfitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(reviewActionsProvider(outfitId).notifier);
    final busy = ref.watch(reviewActionsProvider(outfitId)).isLoading;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('review-reject'),
                onPressed: busy ? null : actions.reject,
                child: const Text('Reject'),
              ),
            ),
            Expanded(
              child: FilledButton(
                key: const ValueKey('review-approve'),
                onPressed: busy ? null : actions.approve,
                child: const Text('Approve'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
