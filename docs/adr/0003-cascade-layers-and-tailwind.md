# ADR 0003 — Cascade layer order and Tailwind 4

Status: accepted (Phase 0, spike S3)

## Context
SPEC §6.2 wants host utilities (Tailwind's `utilities` layer) to override Deckplate without `!important`, and Deckplate
to beat Tailwind's preflight resets. Layer order is fixed by the first `@layer` statement that names a layer, across all
stylesheets in document order. Tested with tailwindcss 4.3.4 (tailwindcss-rails 4.7.0; its output declares
`@layer properties;` then `@layer theme, base, components, utilities;`), Chrome and Firefox 159, computed styles of a
`.dp-button` (in `dp.components`) carrying a `bg-red-500` utility, and a button alone (preflight resets buttons).
Harness: `tmp/spikes/s3/` (not committed).

## Results (identical in Chrome and Firefox)
| Setup | utility beats dp | dp beats preflight | Verdict |
|---|---|---|---|
| 1. `deckplate.css` (only `@layer dp.*`) → Tailwind | yes | **no** | wrong |
| 2. Tailwind → `deckplate.css` | **no** | yes | wrong |
| 3. Tailwind source starts with `@layer theme, base, dp, components, utilities;`, then Deckplate | yes | yes | ok |
| 4. `deckplate.css` starts with the same prelude, linked before Tailwind | yes | yes | ok |
| 5. Tailwind → `deckplate.css` with prelude | **no** | yes | wrong (too late) |
| 6/7. Prelude in **both** files, either link order | yes | yes | ok |
Unlayered host CSS always wins (as intended).

## Decision
1. `deckplate.css` starts with
   `@layer theme, base, dp, components, utilities;` followed by
   `@layer dp.tokens, dp.base, dp.shapes, dp.layout, dp.components, dp.states;`.
   The first line is harmless without Tailwind (empty layers) and makes the "Deckplate linked first" case correct.
2. For Tailwind hosts the installer also inserts the same first line **at the top of the Tailwind source**
   (`app/assets/tailwind/application.css`, before `@import "tailwindcss"`), which makes any link order correct.
   If the file cannot be patched safely the installer prints the line and says where to put it.
3. Documented in `docs/guides/tailwind.md` (Phase 8): "link Deckplate before Tailwind, or add the prelude".
4. An integration check (`bin/integration`, Tailwind variant) asserts both computed-style results from the table above.

## Consequences
- SPEC §6.2 amended to include the prelude line.
- Hosts using other layer names are unaffected except that `theme/base/components/utilities` become known names
  ordered around `dp`; host layers named `components`/`utilities` always override Deckplate.
- `dp.states` stays last inside `dp`, so state styles still beat component styles.
