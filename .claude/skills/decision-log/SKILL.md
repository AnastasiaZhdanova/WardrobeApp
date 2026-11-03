---
name: decision-log
description: Use after finishing each slice, or when asked to explain a decision.
---
After every slice, add exactly one ADR to `docs/adr/`. This skill writes
nothing else.

- File name: next free number, `NNNN-short-title.md`
  (e.g. `0007-offline-sync.md`).
- Add a row for it to the index in `docs/adr/README.md`.
- If it changes an earlier decision, set the old ADR's status to
  "Superseded by NNNN" instead of rewriting it.

Format:

```markdown
# NNNN. Title

Status: Accepted

## Context
## Decision
## Alternatives considered
## Consequences
Positive:
Negative:
## What I would change at production scale
```

Rules:
- One decision per ADR.
- Reference real files and classes (e.g. `lib/features/styling/domain/outfit_rules.dart`, `OutfitRules`).
- Be concrete and honest about trade-offs. The Negative list is never empty.
- No marketing language ("robust", "seamless", "powerful", "best-in-class").
