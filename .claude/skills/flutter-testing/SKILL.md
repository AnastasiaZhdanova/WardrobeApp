---
name: flutter-testing
description: Use when adding features or fixing bugs.
---
- Every use case and parser gets unit tests, including malformed LLM JSON.
- One widget test covers the draft -> swap item -> approve flow with overridden providers.
- Prefer fakes over mocks. No network in tests; the Mock agent is deterministic.
- Run `flutter analyze` and `flutter test` before declaring a slice done.
- Fix the cause of a failing test, never weaken the assertion.
