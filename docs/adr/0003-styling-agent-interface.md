# 0003. StylingAgent interface with Mock and LLM implementations, validated output and fallback

Status: Accepted

## Context
Outfit suggestions may come from a deterministic rule engine or from an
LLM. Tests and the default build must work offline and without keys.
LLM output can be malformed, invent items, or not arrive at all. Personal
data in the wardrobe should not leave the device unnecessarily.

## Decision
- `StylingAgent.suggest(StylingRequest, List<WardrobeItem>)` in
  `lib/features/styling/domain/styling_agent.dart` returns
  `OutfitDraft`s. The interface states that output is never trusted.
- **`MockStylingAgent`** (default, used by every test): keyword matching
  for formality, season, residence and colour, deterministic scoring and
  sorting, so tests can assert exact outfits.
- **`LlmStylingAgent`** (only when built with
  `--dart-define=LLM_API_KEY=...`): calls the Claude Messages API through
  `AnthropicMessagesClient` over `package:http`. The request uses a JSON
  schema output format (`outfit_schema.dart`) in which `item_ids` is an
  `enum` of the real wardrobe ids. `parseOutfits` validates the reply
  again by hand and rejects the whole response on any deviation.
- Timeout 20 s, one retry for timeouts, network errors, 408/429/5xx and
  malformed output (`LlmException.retryable`). No retry for refusals or
  other 4xx.
- **`FallbackStylingAgent`** wraps the LLM agent. On any exception it
  returns mock drafts whose rationale starts with "Offline suggestion."
- Whatever the agent, `RequestOutfits` filters drafts through
  `OutfitRules.violation` (known ids, no duplicates, one residence, one
  item per category, a dress or a top and a bottom) and keeps at most
  three.
- Only id, category, colour, seasons, residence and formality of each
  item are sent to the model. Names, brands and notes stay on the device.

## Alternatives considered
- **Tool use** instead of a JSON schema output: more ceremony for the
  same constrained result.
- **Trusting the schema** without client-side validation: one bad reply
  could show items that don't exist.
- **Showing an error when the LLM fails:** honest, but the stylist would
  be blocked by a network hiccup.
- **A random mock:** makes tests flaky.

## Consequences
Positive:
- A new agent cannot bypass the rules, because they are applied in the
  domain use case, not inside each agent.
- The app always returns drafts, and their source is labelled.

Negative:
- Keyword matching in the mock is naive (no negation or synonyms), so
  suggestions can be poor for unusual wording.
- The free-text request goes to the model unscrubbed and may contain
  personal details.
- A `--dart-define` key is compiled into the binary and can be extracted.
  This is acceptable for local runs only.
- The LLM path is tested against fake HTTP clients, not the live API, so
  prompt quality is not covered by tests.
- Fallback hides persistent LLM failures unless someone reads the label.

## What I would change at production scale
Call the model through a backend that holds the key, authenticates users
and applies rate limits. Redact emails and phone numbers before sending,
log rejection reasons as metrics, and build an evaluation set before
changing prompts or models.
