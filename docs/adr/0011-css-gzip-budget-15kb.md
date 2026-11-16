# ADR 0011 — Raise the gzip CSS budget from 12 KB to 15 KB

Status: accepted (Phase 5 review, owner decision)

## Context
ADR 0009 raised the raw limit to 80 KB and kept gzip at 12 KB. At the end of Phase 5 the bundle is 69.5 KB raw / 11.0 KB gzip (92 % of the
gzip budget) with Phase 6 (feedback components) and the Phase 7 theme switcher still to come.

## Options
1. Split the stylesheet into a core sheet and optional data / feedback sheets (each under its own budget).
2. Raise the gzip limit to 15 KB.
3. Shrink the existing CSS further (little left to gain: comments and blank lines are already removed).

## Decision
Option 2 (owner decision). One stylesheet stays the simplest thing for a host to adopt (a single `stylesheet_link_tag "deckplate"`), and
15 KB gzip is still small next to the fonts (55 KB). The raw limit stays at 80 KB.

## Consequences
- `tools/budgets.rb`, `spec/budgets_spec.rb` and SPEC section 12 say 15 KB gzip.
- If the bundle reaches 15 KB gzip, the next step is option 1 (per-family sheets), recorded in a new ADR; the sources are already
  organised by family (`shapes/`, `layout/`, `components/`), so the build change is small.
