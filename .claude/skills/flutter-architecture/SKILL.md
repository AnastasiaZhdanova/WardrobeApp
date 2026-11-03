---
name: flutter-architecture
description: Use when creating or moving files, features, or dependencies.
---
- Feature-first: `features/<name>/{data,domain,presentation}`.
- `domain` has no Flutter imports and no network/DB packages (freezed/equatable only).
- `presentation` depends on `domain` only; `data` implements `domain` interfaces.
- A feature may import another feature's `domain`, never its `presentation` or `data`.
- Widgets and providers used by more than one feature go in `lib/shared/`,
  which may import features' `domain` only.
- `lib/core` (theme, route names, result, error types, drift schema) imports
  no feature or shared code. `lib/app.dart`, `lib/app_router.dart` and
  `lib/main.dart` assemble the features.
- Errors are sealed types / Result in domain; never raw exceptions in UI.
- `test/architecture_test.dart` enforces these rules; keep it green.
