import 'package:flutter/material.dart';

import '../../features/review/domain/reviewed_outfit.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final DraftStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, color) = switch (status) {
      DraftStatus.draft => (
        'Draft',
        Icons.edit_note_outlined,
        scheme.surfaceContainerHighest,
      ),
      DraftStatus.approved => (
        'Approved',
        Icons.check_circle_outline,
        scheme.primaryContainer,
      ),
      DraftStatus.rejected => (
        'Rejected',
        Icons.cancel_outlined,
        scheme.errorContainer,
      ),
    };
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: color,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
