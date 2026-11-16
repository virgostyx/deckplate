# ADR 0015 — Metric-matched fallback fonts

Status: accepted (Phase 7)

## Context
`font-display: swap` shows text at once in a fallback, then swaps: a layout shift (CLS) when the metrics differ. Antonio is much narrower than Arial.

## Decision
Two local-only faces, "Antonio Fallback" (Arial) and "Share Tech Mono Fallback" (Courier New), with `size-adjust` and
`ascent/descent/line-gap-override` measured in Chromium against the bundled latin files (average width of a-zA-Z0-9 and font bounding box).
They sit right after the web font in `--dp-font-display` and `--dp-font-data`. Preloading both latin fonts (`dp_font_tags`) stays.

## Consequences
No bytes shipped (local()). Values are approximate (canvas metrics, 100 px); where Arial/Courier New are absent the generic fallback applies as before.
If the fonts are replaced, re-measure.
