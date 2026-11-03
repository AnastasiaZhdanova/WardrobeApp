import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/app_database.dart';
import 'features/wardrobe/data/drift_wardrobe_repository.dart';
import 'shared/providers/wardrobe_data_providers.dart';

/// Composition root: the only place that binds domain interfaces to their
/// data-layer implementations.
void main() {
  runApp(
    ProviderScope(
      overrides: [
        wardrobeRepositoryProvider.overrideWith(
          (ref) => DriftWardrobeRepository(ref.watch(appDatabaseProvider)),
        ),
      ],
      child: const WardrobeApp(),
    ),
  );
}
