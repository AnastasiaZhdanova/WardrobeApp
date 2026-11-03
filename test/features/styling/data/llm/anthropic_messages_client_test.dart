import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wardrobe_app/features/styling/data/llm/anthropic_messages_client.dart';
import 'package:wardrobe_app/features/styling/data/llm/llm_exceptions.dart';

AnthropicMessagesClient _client(
  MockClientHandler handler, {
  Duration timeout = const Duration(seconds: 5),
}) => AnthropicMessagesClient(
  apiKey: 'test-key',
  httpClient: MockClient(handler),
  timeout: timeout,
);

http.Response _reply(Map<String, Object?> json, [int status = 200]) =>
    http.Response(jsonEncode(json), status);

void main() {
  test('sends auth, version and fallback, returns first text block', () async {
    late http.Request sent;
    final client = _client((request) async {
      sent = request;
      return _reply({
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'thinking', 'thinking': ''},
          {'type': 'text', 'text': '{"outfits":[]}'},
        ],
      });
    });

    final text = await client.createMessage({'model': 'm'});

    expect(text, '{"outfits":[]}');
    expect(sent.headers['x-api-key'], 'test-key');
    expect(sent.headers['anthropic-version'], '2026-10-21');
    expect(sent.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
    expect(jsonDecode(sent.body), {'model': 'm', 'fallbacks': 'default'});
  });

  test('refusal is not retryable', () async {
    final client = _client(
      (_) async => _reply({'stop_reason': 'refusal', 'content': <Object>[]}),
    );

    await expectLater(
      client.createMessage({}),
      throwsA(isA<LlmRefusalException>()),
    );
    expect(const LlmRefusalException().retryable, isFalse);
  });

  test('truncated output is a format error', () async {
    final client = _client(
      (_) async => _reply({
        'stop_reason': 'max_tokens',
        'content': [
          {'type': 'text', 'text': '{"outf'},
        ],
      }),
    );

    await expectLater(
      client.createMessage({}),
      throwsA(isA<LlmFormatException>()),
    );
  });

  test('HTTP status decides retryability', () async {
    for (final (status, retryable) in [
      (429, true),
      (529, true),
      (500, true),
      (400, false),
      (401, false),
    ]) {
      final client = _client((_) async => _reply({}, status));
      await expectLater(
        client.createMessage({}),
        throwsA(
          isA<LlmHttpException>().having(
            (e) => e.retryable,
            'retryable for $status',
            retryable,
          ),
        ),
      );
    }
  });

  test('a hanging request times out', () async {
    final client = _client(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      client.createMessage({}),
      throwsA(isA<LlmTimeoutException>()),
    );
  });

  test('network errors are retryable', () async {
    final client = _client((_) async => throw http.ClientException('offline'));

    await expectLater(
      client.createMessage({}),
      throwsA(isA<LlmNetworkException>()),
    );
  });

  test('non-JSON body is a format error', () async {
    final client = _client((_) async => http.Response('<html>', 200));

    await expectLater(
      client.createMessage({}),
      throwsA(isA<LlmFormatException>()),
    );
  });
}
