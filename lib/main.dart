import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'core/db/app_database.dart';
import 'features/review/data/drift_review_repository.dart';
import 'features/styling/data/fallback_styling_agent.dart';
import 'features/styling/data/llm/anthropic_messages_client.dart';
import 'features/styling/data/llm/llm_styling_agent.dart';
import 'features/styling/data/mock_styling_agent.dart';
import 'features/styling/domain/styling_agent.dart';
import 'features/styling/presentation/styling_providers.dart';
import 'features/wardrobe/data/drift_wardrobe_repository.dart';
import 'shared/providers/review_data_providers.dart';
import 'shared/providers/wardrobe_data_providers.dart';

// Both are compile-time values: `flutter run --dart-define=LLM_API_KEY=...`.
const _llmApiKey = String.fromEnvironment('LLM_API_KEY');
const _llmModel = String.fromEnvironment(
  'LLM_MODEL',
  defaultValue: 'claude-sonnet-5-5',
);

/// The deterministic mock unless an API key was provided at build time.
StylingAgent _stylingAgent() => _llmApiKey.isEmpty
    ? const MockStylingAgent()
    : FallbackStylingAgent(
        primary: LlmStylingAgent(
          AnthropicMessagesClient(
            apiKey: _llmApiKey,
            httpClient: http.Client(),
          ),
          model: _llmModel,
        ),
        fallback: const MockStylingAgent(),
      );

/// Composition root: the only place that binds domain interfaces to their
/// data-layer implementations.
void main() {
  runApp(
    ProviderScope(
      overrides: [
        wardrobeRepositoryProvider.overrideWith(
          (ref) => DriftWardrobeRepository(ref.watch(appDatabaseProvider)),
        ),
        reviewRepositoryProvider.overrideWith(
          (ref) => DriftReviewRepository(ref.watch(appDatabaseProvider)),
        ),
        stylingAgentProvider.overrideWithValue(_stylingAgent()),
      ],
      child: const WardrobeApp(),
    ),
  );
}
