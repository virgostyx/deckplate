# Open questions

Format: one entry per question. The agent applies the safest default, records it here, and continues.
The owner answers by editing the entry (change **Status** to `answered`) and the agent follows up.

## Template

### Q-000 — Short title
- **Phase / task**: e.g. Phase 2, Elbow
- **Question**: …
- **Default applied**: …
- **Why this default is safe**: …
- **Status**: open | answered
- **Answer**: …

## Pre-filled decisions for the owner (please confirm or change)

### Q-001 — Where will the gem be distributed?
- **Phase / task**: Phase 8, release
- **Question**: Private only (git remote / `path:`), or public on RubyGems after the legal checklist?
- **Default applied**: private only; no publication step is executed by the agent.
- **Status**: answered
- **Answer**: private only (confirmed by the owner).

### Q-002 — Is the author's existing Rails ViewComponent draft to be reused?
- **Phase / task**: Phase 1–3
- **Question**: The earlier style guide (§14) contains Rails component drafts. Port ideas only, or port code?
- **Default applied**: ideas only; components are rewritten test-first under the new naming (`Deckplate::`, `dp-`).
- **Status**: answered
- **Answer**: ideas only (confirmed by the owner).

### Q-003 — Default success colour
- **Phase / task**: Phase 1, themes
- **Question**: In `classic`, success is pale yellow (per the author's guide). Should `classic` map success to a
  green instead?
- **Default applied**: pale-canary (yellow) with mandatory text/icon; `daylight` maps success to a green.
- **Status**: answered
- **Answer**: pale-canary in `classic` (confirmed by the owner).

## Raised during implementation

### Q-004 — WebKit cannot run on the dev machine
- **Phase / task**: Phase 0, spike S2 (elbow); later all of `bin/visual`
- **Question**: Playwright's WebKit needs a system library (`libmanette-0.2-0`, installed with `sudo apt-get install
  libmanette-0.2-0` or `sudo npx playwright install-deps`). May this be installed on the dev machine?
- **Default applied**: ADR 0002 accepted on Chrome + Firefox evidence only; Safari/WebKit verification is a pending item
  to re-run `elbow.mjs` and later the visual suite. The agent does not run `sudo`.
- **Status**: answered
- **Answer**: owner installed `libmanette-0.2-0`; WebKit run done, ADR 0002 verified on all three engines.

### Q-005 — Ruby version on the dev machine
- **Phase / task**: Phase 0, skeleton
- **Question**: `~/.rbenv/version` is 3.3.0, which cannot load Rails 8.1.4.1 (syntax error fixed in Ruby 3.3.1). CLAUDE.md
  says 3.3.5.
- **Default applied**: project-local `.ruby-version` = 3.3.5 (installed); the global rbenv version is untouched.
- **Status**: answered
- **Answer**: keep the project-local `.ruby-version` (confirmed by the owner).

### Q-006 — Namespace of controls and navigation components
- **Phase / task**: Phase 3, Button
- **Question**: SPEC section 3 lists a `controls/` and `navigation/` folder, but the normative API examples (sections 4 and 8.6)
  write `Deckplate::ButtonComponent` and `Deckplate::NavComponent` (no sub-namespace).
- **Default applied**: follow the API examples: controls and navigation components are top-level constants
  (`Deckplate::ButtonComponent`, `Deckplate::TabsComponent`, ...) in `app/components/deckplate/`. Shapes, layout, forms, data
  and feedback keep their namespaces (`Shapes::`, `Layout::`, `Forms::`, `Data::`, `Feedback::`).
- **Why this default is safe**: the public API is what users type; folder layout is internal and can be regrouped later with
  Zeitwerk `collapse` without changing any constant.
- **Status**: open

### Q-007 — Size of the visual baselines
- **Phase / task**: Phase 4 review, `bin/visual`
- **Question**: Baselines weigh 29 MB for 1,215 screenshots (5 themes x 3 widths per preview) and grow with every phase. Reduce the
  matrix, move them to Git LFS, or keep them as they are?
- **Default applied / decision**: keep the full matrix in Git, unchanged.
- **Status**: answered
- **Answer**: no change (owner decision). Revisit if the baselines pass 80 MB or the repository becomes slow to clone; the first
  options to consider then are a reduced matrix for secondary previews and Git LFS.
