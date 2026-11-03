import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error_message.dart';
import '../../../core/router/routes.dart';
import '../../../shared/providers/review_data_providers.dart';
import '../../../shared/widgets/attribute_labels.dart';
import '../../../shared/widgets/outfit_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../wardrobe/domain/wardrobe_item.dart';
import '../domain/styling_request.dart';
import 'styling_providers.dart';

const _examples = [
  'Gallery opening in the city on Thursday',
  'Lunch at the villa by the sea, it will be hot',
  'Cold weekend walk with the dog in the country',
];

class StylingRequestScreen extends ConsumerStatefulWidget {
  const StylingRequestScreen({super.key});

  @override
  ConsumerState<StylingRequestScreen> createState() =>
      _StylingRequestScreenState();
}

class _StylingRequestScreenState extends ConsumerState<StylingRequestScreen> {
  final _text = TextEditingController();
  Residence? _residence;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(stylingControllerProvider.notifier)
        .submit(StylingRequest(text: _text.text, residence: _residence));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stylingControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Style request')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          TextField(
            key: const ValueKey('request-text'),
            controller: _text,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'What is the occasion?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final example in _examples)
                ActionChip(
                  label: Text(example),
                  onPressed: () => _text.text = example,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Where are you?', style: text.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final residence in Residence.values)
                ChoiceChip(
                  label: Text(residence.label),
                  selected: _residence == residence,
                  onSelected: (selected) =>
                      setState(() => _residence = selected ? residence : null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('request-submit'),
            onPressed: state.isLoading ? null : _submit,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Suggest outfits'),
          ),
          const SizedBox(height: 24),
          ...switch (state) {
            AsyncLoading() => [
              const Center(child: CircularProgressIndicator()),
            ],
            AsyncError(:final error) => [
              Text(errorMessage(error), textAlign: TextAlign.center),
            ],
            AsyncData(value: final ids?) => _results(ids),
            AsyncData() => const <Widget>[],
          },
        ],
      ),
    );
  }

  List<Widget> _results(List<String> ids) => [
    const _DraftNotice(),
    const SizedBox(height: 12),
    for (final id in ids) ...[
      _ReviewedOutfitCard(id: id),
      const SizedBox(height: 12),
    ],
  ];
}

/// Shows the live review state, so a decision made on the review screen is
/// visible on return.
class _ReviewedOutfitCard extends ConsumerWidget {
  const _ReviewedOutfitCard({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfit = ref.watch(reviewedOutfitProvider(id)).value;
    if (outfit == null) return const SizedBox.shrink();
    return OutfitCard(
      key: ValueKey(id),
      title: outfit.title,
      subtitle: outfit.rationale,
      itemIds: outfit.itemIds,
      trailing: StatusChip(status: outfit.status),
      onTap: () => context.push(Routes.review(id)),
    );
  }
}

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          spacing: 8,
          children: [
            Icon(Icons.verified_user_outlined),
            Expanded(
              child: Text(
                'These are drafts. Nothing is final until your stylist '
                'approves it. Tap one to review.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
