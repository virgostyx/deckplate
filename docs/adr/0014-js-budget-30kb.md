# ADR 0014 — Raise the JS budget to 30 KB raw / 8 KB gzip

Status: accepted (Phase 7, owner decision, Q-008)

## Context
Phase 7 added dp-sound, dp-theme and dp-flicker. JS reached 20.7 KB raw / 6.4 KB gzip against 20 / 6.

## Options
1. Strip comments from shipped JS. 2. Drop a feature. 3. Raise the budget.

## Decision
Option 3. Controllers are loaded individually by the importmap, and each is small; the budget measures all of them together.

## Consequences
`tools/budgets.rb` and SPEC section 12 say 30 KB raw / 8 KB gzip. Revisit with a build step (comment stripping) if it nears the limit.
