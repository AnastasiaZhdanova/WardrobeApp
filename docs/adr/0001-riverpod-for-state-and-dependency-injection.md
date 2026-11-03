# 0001. Riverpod (with code generation) for state and dependency injection

Status: Accepted

## Context
The app has three kinds of state: async data loaded from drift (wardrobe
items, the review queue), UI state (wardrobe filters, the app lock), and
one-off commands (request outfits, approve, reject, swap). Every boundary
(repositories, the styling agent, the app lock's platform channel) has to be
replaceable by a fake in widget tests without a mocking library.

## Decision
- `flutter_riverpod` 3 with `riverpod_annotation` / `riverpod_generator`.
  Providers are `@riverpod` functions or `Notifier` classes in each
  feature's `presentation/` folder, or in `lib/shared/providers/` when
  several features need them (ADR 0002).
- Boundary providers (`wardrobeRepositoryProvider`, `reviewRepositoryProvider`,
  `stylingAgentProvider`, `deviceAuthProvider`) throw
  `UnimplementedError` until overridden. `lib/main.dart` overrides them
  with real implementations; tests override them with the fakes in
  `test/fakes/` through `test/helpers/pump_wardrobe_app.dart`.
- Domain code returns `Result<T>` (`lib/core/result.dart`). Presentation
  turns it into provider state in one way only: `Result.valueOrThrow`
  inside a `FutureProvider` or `AsyncValue.guard`. `errorMessage()` in
  `lib/core/error_message.dart` is the single place that turns an error
  into text.
- Async commands that can race (`StylingController.request`) drop stale
  results with a generation counter plus `ref.mounted`.

## Alternatives considered
- **Bloc / Cubit:** explicit events and good tooling, but a class per
  state and per event for small features, and DI needs a second package
  (`get_it` or `RepositoryProvider`).
- **Provider:** simpler, but no compile-time-safe overrides, and async
  state and disposal are left to the developer.
- **Riverpod without codegen:** fewer build steps, more hand-written
  provider boilerplate and weaker typing of family parameters.

## Consequences
Positive:
- One mechanism covers DI, caching, async state and test overrides.
- Widget tests run the real screens and providers with fakes only at the
  boundaries.

Negative:
- A missing override fails at runtime (`UnimplementedError`), not at
  compile time.
- Code generation adds a `build_runner` step to every fresh clone and to
  CI (ADR 0002 lists the layering this supports).
- `valueOrThrow` uses an exception to move a failure into `AsyncError`.
  `AsyncValue.guard` also catches programmer errors, which then show the
  generic "Something went wrong." message instead of crashing in debug.
- The stale-result guard ignores old responses but does not cancel the
  underlying HTTP call.

## What I would change at production scale
Add `riverpod_lint` to CI, wrap commands in a small "mutation" helper
instead of hand-written counters, and add a test that fails if any
boundary provider is left un-overridden in `main.dart`.
