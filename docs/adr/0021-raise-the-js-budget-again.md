# ADR 0021 — Raise the JS budget to 40 KB raw / 12 KB gzip

Status: accepted (Phase 9, owner decision)

## Context
ADR 0014 set 30 KB raw / 8 KB gzip and said to revisit it when it neared the limit. Phase 9 added the keypad, Tooltip placement and delay, and the sortable
list (dp-sortable, about 1.2 KB gzip on its own): JS reached 28.4 KB raw / 8.7 KB gzip.

## Options
1. Strip comments from the shipped JS (needs a build step). 2. Make dp-sortable optional (a separate import). 3. Raise the budget.

## Decision
Option 3, chosen by the owner. The controllers are loaded one by one by the importmap and each is small; the budget measures all of them together, so it is a
conservative bound for an app that uses every component.

## Consequences
`tools/budgets.rb`, `spec/budgets_spec.rb` and SPEC section 12 say 40 KB raw / 12 KB gzip. Revisit with comment stripping or per-family JS if it nears the limit.
