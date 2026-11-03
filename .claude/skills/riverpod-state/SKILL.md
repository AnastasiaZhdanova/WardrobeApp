---
name: riverpod-state
description: Use when writing providers, controllers, or UI state.
---
- Riverpod with codegen (`@riverpod`). One notifier per screen concern.
- UI state is a sealed/freezed class (loading / data / error).
- No business logic in widgets; widgets only read state and call notifier methods.
- Repositories and the StylingAgent are exposed via providers so tests can override them.
- Prefer `AsyncNotifier` for async flows; handle cancellation and disposal explicitly.
