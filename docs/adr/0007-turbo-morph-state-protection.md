# ADR 0007 — Stateful controllers protect their DOM state during Turbo morphs

Status: accepted (Phase 3)

## Context
Turbo 8 page refreshes can morph the DOM (`turbo_refreshes_with method: :morph`). Morphing copies attributes from the server's HTML
onto the live DOM. Our components keep UI state *in the DOM*: `aria-selected`/`tabindex`/`hidden` (Tabs), `aria-expanded`, roving
`tabindex` and the CSSOM position (Menu), the `open` attribute set by `showModal()` (Modal), the input `value` and the `--dp-pct`
style (Slider). The system specs in `spec/system/turbo_spec.rb` showed all four being reset by a morph refresh (selected tab back to
the first, menu `aria-expanded=false`, dialog closed, slider back to 72).

## Options
1. `data-turbo-permanent` on the components: requires an `id`, and also blocks legitimate server updates of the content.
2. Each controller cancels the morph of the attributes it owns, via the cancelable `turbo:before-morph-attribute` event
   (`event.detail.attributeName`), and re-syncs derived text afterwards (`turbo:morph-element`).
3. Keep the state in `sessionStorage`/URL and restore it after each morph.

## Decision
Option 2. Each stateful controller defines `keepState(event)`, wired by its component through `data-action`
(`turbo:before-morph-attribute->dp-<name>#keepState`), and lists the attributes it owns. Content (labels, panels, items) still updates
from the server; only attributes that encode user interaction state are protected.

## Consequences
- New stateful controllers must define `keepState` and get a morph test in `spec/system/turbo_spec.rb` (Definition of Done point 8).
- If the server legitimately needs to change a protected attribute (e.g. force another tab), it must change the element's `id`
  (Turbo then replaces the element) or use a Turbo Stream `replace`.
- Controllers stay idempotent on `connect`/`disconnect` (menu and modal close themselves in `disconnect`, so Turbo's cache snapshot
  never contains an open overlay).
