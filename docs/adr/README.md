# Architecture Decision Records

One decision per file, numbered in order: `NNNN-short-title.md`. An
accepted ADR is not rewritten; a later decision that replaces it gets a
new number and the old one is marked "Superseded by NNNN".

| # | Decision | Status |
| --- | --- | --- |
| [0001](0001-riverpod-for-state-and-dependency-injection.md) | Riverpod (with code generation) for state and dependency injection | Accepted |
| [0002](0002-feature-first-layering.md) | Feature-first folders with domain / data / presentation layers | Accepted |
| [0003](0003-styling-agent-interface.md) | StylingAgent interface with Mock and LLM implementations, validated output and fallback | Accepted |
| [0004](0004-stylist-approval-required.md) | Human in the loop: draft -> approved \| rejected, and the agent can never approve | Accepted |
| [0005](0005-drift-local-persistence.md) | drift for local persistence, seeded once, with no sync yet | Accepted |
| [0006](0006-app-lock-platform-channel.md) | App lock through a hand-written MethodChannel | Accepted |

## Template

```markdown
# NNNN. Title

Status: Proposed | Accepted | Superseded by NNNN

## Context
## Decision
## Alternatives considered
## Consequences
Positive:
Negative:
## What I would change at production scale
```
