# 0002. Feature-first folders with domain / data / presentation layers

Status: Accepted

## Context
Four features (wardrobe, styling, review, app lock) share a few models and
must be testable without Flutter, a database or the network. The core
rule "agent output is never final" has to live somewhere the UI cannot
bypass. Some widgets and providers (item images, outfit cards, the
wardrobe and review data) are needed by more than one feature.

## Decision
- `lib/features/<feature>/{domain,data,presentation}`.
- **domain** is pure Dart: entities (`WardrobeItem`, `OutfitDraft`,
  `ReviewedOutfit`), interfaces (`WardrobeRepository`, `StylingAgent`,
  `ReviewRepository`, `DeviceAuth`) and use cases (`RequestOutfits`,
  `StylistReview`). It never imports Flutter, drift or `http`.
- **data** implements domain interfaces (`DriftWardrobeRepository`,
  `MockStylingAgent`, `LlmStylingAgent`, `MethodChannelDeviceAuth`).
- **presentation** depends on domain and never on data.
- **Across features:** a feature may import another feature's domain, but
  never its presentation or data.
- **`lib/shared/`** holds what several features render or watch:
  - widgets: `WardrobeImage`, `OutfitCard`, `StatusChip` and the attribute
    labels;
  - providers: `wardrobeRepositoryProvider`, `wardrobeItemsProvider`,
    `reviewRepositoryProvider`, `stylistReviewProvider`,
    `reviewQueueProvider`.

  Shared code may import features' domain only.
- **`lib/core`** (result types, route names, theme, drift schema) imports
  no feature or shared code. The drift schema stores enums by name, so it
  does not need the feature enums.
- **The app level assembles features:**
  - `lib/app_router.dart` maps routes to screens;
  - `lib/main.dart` is the composition root and the only file that imports
    data implementations to wire them in.
- **`test/architecture_test.dart` enforces these rules.** It reads the
  import directives of every hand-written file in `lib/` and fails if:
  - domain imports Flutter, drift, `http`, shared code, or any data or
    presentation file;
  - presentation imports data;
  - a feature imports another feature's presentation or data;
  - core imports feature or shared code;
  - shared code imports data or presentation.

  It runs with `flutter test`, so CI fails on a violation.

## Alternatives considered
- **Layer-first** (`lib/data`, `lib/domain`, `lib/ui`): fine for small
  apps, but one feature's change touches three distant folders.
- **One package per feature (melos):** the compiler would enforce
  boundaries, but it's heavy setup for four features.
- **A custom analyzer lint** instead of a test: violations would show up
  in the IDE, but it's more setup than a 150-line test.
- **No domain layer** (widgets call repositories): less code, but the
  review rules would be spread across screens.

## Consequences
Positive:
- Use cases and rules are unit-tested without widgets
  (`test/features/*/domain/`).
- The data layer can be swapped per boundary, as `main.dart` does for the
  LLM agent.
- Layering mistakes fail CI instead of relying on review. The first run
  caught the router living in `lib/core` while importing feature screens,
  which is why it moved to `lib/app_router.dart`.

Negative:
- `lib/shared/` can turn into a dumping ground. Nothing limits what goes
  there except that it may not depend on data or presentation.
- Features still depend on each other's domain (`styling` and `review` on
  `wardrobe`; `review` on `styling`'s `OutfitDraft` and `OutfitRules`), so
  removing a feature means editing others.
- The architecture test parses imports with a regular expression. It
  doesn't see conditional imports and doesn't check `part` files or
  package dependencies.
- The drift schema in `core` duplicates the shape of `WardrobeItem` and
  `ReviewedOutfit`, and mapping code lives in each repository.

## What I would change at production scale
Split features into packages once several teams work on them, so the
compiler enforces the boundaries the test checks today. Move the outfit
rules into their own domain package that both `styling` and `review`
depend on.
