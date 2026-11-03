---
name: styling-agent-layer
description: Use for any AI/agent code, prompts, or output parsing.
---
- Interface: `Future<List<OutfitDraft>> suggest(StylingRequest, List<WardrobeItem>)`.
- LLM output is strict JSON; validate against a schema and reject unknown item ids.
- Timeout + cancellation, one retry, then fall back to MockStylingAgent.
- Drafts are immutable. Status changes only through stylist-review use cases
  (draft -> approved | rejected). The agent can never set `approved`.
- Send only item ids and attributes to the LLM. No personal identifiers.
  Never log prompts or user text.
- API key only via `--dart-define`; never committed.
