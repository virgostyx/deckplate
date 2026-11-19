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
- **Status**: answered
- **Answer**: keep the top-level constants (owner decision). SPEC section 3 is aligned below.

### Q-007 — Size of the visual baselines
- **Phase / task**: Phase 4 review, `bin/visual`
- **Question**: Baselines weigh 29 MB for 1,215 screenshots (5 themes x 3 widths per preview) and grow with every phase. Reduce the
  matrix, move them to Git LFS, or keep them as they are?
- **Default applied / decision**: keep the full matrix in Git, unchanged.
- **Status**: answered
- **Answer**: no change (owner decision). Revisit if the baselines pass 80 MB or the repository becomes slow to clone; the first
  options to consider then are a reduced matrix for secondary previews and Git LFS.

### Q-008 — JS budget exceeded by Phase 7 (dp-sound, dp-theme, dp-flicker)
- **Phase / task**: Phase 7, sound
- **Question**: JS is 20.7 KB raw / 6.4 KB gzip against budgets of 20 / 6 (SPEC section 12). Raise the budget (ADR, like 0011), or cut JS
  (e.g. strip comments from shipped JS as is done for CSS, or drop a feature)?
- **Default applied**: budget left unchanged; `spec/budgets_spec.rb` stays red on purpose until the owner decides. Nothing was weakened.
- **Status**: answered
- **Answer**: raise the budget (owner). ADR 0014: 30 KB raw / 8 KB gzip. Raised again in Phase 9 (ADR 0021): 40 KB raw / 12 KB gzip.

### Q-009 — `classic`: primary and warning are almost the same orange
- **Phase / task**: Phase 7, theme polish review
- **Question**: `primary` #FF9933 and `warning` #FF9900 are hard to tell apart. Change one (the palette comes from the author's earlier guide), or keep?
- **Default applied**: palette unchanged; no component relies on colour alone (icon + text for warnings); documented in `docs/guides/accessibility.md`.
- **Why this default is safe**: no visual baselines or contrast results change; the risk is a host using both roles for different meanings.
- **Status**: answered
- **Answer**: keep the palette (owner decision); the limitation stays documented in `docs/guides/accessibility.md`.

### Q-010 — Manual screen reader smoke test postponed
- **Phase / task**: Phase 7, "done when" (accessibility pass with screen reader notes)
- **Question**: The manual Orca test (`docs/guides/screen-reader-checklist.md`) was judged too complex for now. Run it before a release?
- **Default applied**: postponed (owner decision); `accessibility.md` states that no real screen reader test was done. Not a gap to hide: it blocks any public release (add to the Phase 8 checklist).
- **Status**: answered
- **Answer**: postponed by the owner. To be done (or accepted as a documented limitation) before the first public release.
