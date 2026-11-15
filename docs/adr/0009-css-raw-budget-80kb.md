# ADR 0009 — Raise the raw CSS budget from 60 KB to 80 KB

Status: accepted (Phase 4 review, owner decision)

## Context
SPEC section 12 set `deckplate.css` at <= 60 KB raw / <= 12 KB gzip. After Phase 4 the shipped bundle (comments and blank lines already
stripped, ADR-less change in Phase 4) is 55.9 KB raw / 8.9 KB gzip. Data display (Phase 5) and feedback (Phase 6) will add roughly
20 KB raw, so the raw limit would be crossed in the middle of Phase 5 while gzip stays comfortable.

## Options
1. Raise the raw limit to 80 KB, keep gzip at 12 KB.
2. Shrink the CSS: full minification of the bundle and/or per-family stylesheets.
3. Keep 60 KB and decide when it breaks.

## Decision
Option 1. The size that matters on the wire is the gzip size, which keeps its original limit (12 KB, currently 74 % used at the end of
Phase 4). A readable shipped bundle (one rule per line) is worth more than 20 KB of uncompressed bytes that servers compress anyway.

## Consequences
- `tools/budgets.rb`, `spec/budgets_spec.rb` and SPEC section 12 now say 80 KB raw.
- If gzip reaches 12 KB, the next step is options 2 (per-family sheets first), recorded in a new ADR.
- JS (20 KB / 6 KB gzip) and fonts (90 KB) are unchanged.
