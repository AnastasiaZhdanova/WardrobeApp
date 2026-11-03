import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_exceptions.dart';

/// Minimal raw-HTTP client for the Claude Messages API (Dart has no official
/// SDK). Returns the first text block of the reply. Never logs requests or
/// responses: they contain the client's own words.
class AnthropicMessagesClient {
  AnthropicMessagesClient({
    required this.apiKey,
    required this.httpClient,
    this.timeout = const Duration(seconds: 20),
  });

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  final String apiKey;
  final http.Client httpClient;
  final Duration timeout;

  Future<String> createMessage(Map<String, Object?> body) async {
    // The abort trigger cancels the socket; `.timeout` covers clients
    // (like test fakes) that ignore it.
    final abort = Completer<void>();
    final timer = Timer(timeout, abort.complete);
    final request =
        http.AbortableRequest('POST', _endpoint, abortTrigger: abort.future)
          ..headers.addAll({
            'content-type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2026-10-21',
            // Server-side fallback when the model declines on policy grounds.
            'anthropic-beta': 'server-side-fallback-2026-07-01',
          })
          ..body = jsonEncode({...body, 'fallbacks': 'default'});

    final http.Response response;
    try {
      // Time out the whole exchange: connecting, headers and body.
      response = await Future(
        () async => http.Response.fromStream(await httpClient.send(request)),
      ).timeout(timeout);
    } on TimeoutException {
      throw const LlmTimeoutException();
    } on http.RequestAbortedException {
      throw const LlmTimeoutException();
    } on http.ClientException catch (e) {
      throw LlmNetworkException(e.message);
    } finally {
      timer.cancel();
    }

    if (response.statusCode != 200) throw LlmHttpException(response.statusCode);
    return _firstText(response.body);
  }

  static String _firstText(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      throw const LlmFormatException('Response is not JSON.');
    }
    if (json is! Map<String, Object?>) {
      throw const LlmFormatException('Response is not an object.');
    }
    switch (json['stop_reason']) {
      case 'refusal':
        throw const LlmRefusalException();
      case 'max_tokens':
        throw const LlmFormatException('Response was truncated.');
    }
    // Thinking blocks may precede the answer; take the first text block.
    final content = json['content'];
    if (content is List<Object?>) {
      for (final block in content) {
        if (block case {'type': 'text', 'text': final String text}) {
          return text;
        }
      }
    }
    throw const LlmFormatException('Response has no text block.');
  }
}
