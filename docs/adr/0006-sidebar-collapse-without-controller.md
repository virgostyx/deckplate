# ADR 0006 — Frame sidebar collapse uses a native popover (no `dp-sidebar` controller)

Status: accepted (Phase 3)

## Context
SPEC section 9 lists a `dp-sidebar` Stimulus controller ("mobile collapse of the frame sidebar"). PLAN Phase 3 wants the sidebar
nav to work inside `Frame` with mobile collapse. Phase 2 had already built the collapse with the HTML `popover` attribute and a
container query.

## Options
1. `dp-sidebar` controller toggling a class/hidden state.
2. Native popover (`popovertarget`) on the sidebar wrapper, restyled inline from 48rem with plain CSS.

## Decision
Option 2. Verified in `spec/system/frame_spec.rb` at 375, 768 and 1280 px: the "Menu" button opens the sidebar as a drawer, Escape and
light dismiss close it, focus returns to the button, and from 48rem the sidebar is a normal grid column (author CSS overrides the UA
popover styles). This removes about 0.5 KB of JavaScript and a class of Turbo cache problems (nothing to disconnect).
CLAUDE.md rule 11 ("prefer native HTML and add Stimulus only where behaviour requires it") applies.

## Consequences
- `dp-sidebar` is removed from the controller list in SPEC section 9.
- The drawer does not close by itself when a link inside is followed by a Turbo visit that keeps the same frame (the whole page body
  is replaced by Turbo in the usual case, which resets it). If a host keeps the frame across visits (`data-turbo-permanent`), it
  must call `hidePopover()` on `turbo:before-visit`; documented in the Turbo guide (Phase 8).
