# 0004. Human in the loop: draft -> approved | rejected, and the agent can never approve

Status: Accepted

## Context
Agent output is a proposal. A stylist must decide on every outfit, may
adjust it first, and the record must show what the agent proposed versus
what was approved.

## Decision
- `OutfitDraft` (agent output) has no status field, so an agent cannot
  express approval at all.
- `StylistReview` (`lib/features/review/domain/stylist_review.dart`) is
  the only code that creates `ReviewedOutfit`s and changes their status:
  - `submit` stores drafts with `DraftStatus.draft`.
  - `approve` and `reject` are allowed only from `draft`.
  - Both end states are final; a second decision returns
    `InvalidTransitionFailure`.
- `swapItem` works only on drafts and only to an item from `swapOptions`
  (same category and residence, not already in the outfit). The result is
  checked again with `OutfitRules`.
- `ReviewedOutfit` keeps `proposedItemIds` (agent) next to `itemIds`
  (after swaps), so stylist edits are visible (`isEditedByStylist`).
- Reviews are stored in drift by `DriftReviewRepository`. Screens watch
  them through `reviewQueueProvider`, a stream, so a decision shows up
  everywhere without manual refresh.

## Alternatives considered
- **Status on the agent output, with agents told not to set it:** relies
  on every implementation behaving.
- **Transition methods on the entity:** shorter, but the entity would
  need repository access to persist and to check the wardrobe.
- **A sealed union** (`Draft | Approved | Rejected`): the compiler would
  forbid invalid states. More code for three states.
- **Undo after approval:** useful, but it weakens "approved is final"
  and needs an audit trail.

## Consequences
Positive:
- Every transition is unit-tested in one place
  (`test/features/review/domain/stylist_review_test.dart`), and the full
  flow is covered by `review_flow_test.dart`.
- "What the agent suggested vs. what the stylist approved" is stored, not
  inferred.

Negative:
- `ReviewedOutfit` is a freezed class with `copyWith`, so "only
  `StylistReview` changes status" is a convention backed by tests, not a
  compiler guarantee.
- No user roles: whoever unlocks the device acts as the stylist. There is
  no `approvedBy`.
- Decisions are local to one device and cannot be reversed.
- Review ids are timestamp-based (`microsecondsSinceEpoch-index`), which
  is unique on one device but not across devices.

## What I would change at production scale
Make transitions server-authoritative with a stylist role and
`approvedBy`. Use UUIDs, model status as a sealed union, and add an
audited "reopen" transition instead of undo.
