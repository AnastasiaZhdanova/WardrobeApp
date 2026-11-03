# WardrobeApp — project rules

A private wardrobe app with an AI styling assistant where a human stylist
stays in control. Small scope, high polish, every decision explainable.

## Scope (do not expand without asking)
1. Wardrobe: grid of items (mock data + local images), filters by season /
   color / residence, item detail screen.
2. Styling request: natural-language request -> StylingAgent returns 2-3
   outfit drafts built only from wardrobe items.
3. Stylist review: draft -> approved | rejected; stylist can swap an item
   before approving. Agent output is never final without approval.
4. One platform-channel feature (app lock) to show native iOS/Android depth.

## Stack
Flutter stable, Dart 3, Riverpod (codegen), go_router, freezed, drift
(local persistence), flutter_test. CI: GitHub Actions (analyze + test).

## Architecture
Feature-first: `lib/features/<name>/{data,domain,presentation}`.
Cross-feature widgets and providers in `lib/shared`, infrastructure in
`lib/core`. `test/architecture_test.dart` enforces the import rules. See
`.claude/skills/flutter-architecture`.

## Workflow
- Work in vertical slices. Propose a plan first and wait for approval.
- After each slice: `flutter analyze` and `flutter test` must pass, then
  add an ADR to `docs/adr/` via the decision-log skill.
- Prefer small, readable code over cleverness. No dead code, no TODO dumps.
- No secrets in the repo. LLM key only via `--dart-define`.
- StylingAgent has a deterministic Mock implementation used by default and
  in all tests.

## Definition of done for a slice
Compiles, analyzer clean, tests added, ADR added, can be demoed in under
60 seconds.
