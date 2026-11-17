# Deckplate — Build plan

How to use this plan: work **top to bottom**. A phase is finished only when its "Done when" list is fully
true and `bin/ci` is green. Tasks inside a phase are ordered; each task is test-first.
The design and API are in `docs/SPEC.md`; working rules are in `CLAUDE.md`.

Legend: **[T]** write the test first · **[ADR]** record a decision in `docs/adr/` · **[Q]** if unsure, log in
`docs/QUESTIONS.md` and apply the safest default.

Overview and dependencies:

| Phase | Theme | Depends on | Size |
|---|---|---|---|
| 0 | Bootstrap + risk spikes | – | M |
| 1 | Foundations (tokens, themes, base component, Lookbook) | 0 | M |
| 2 | Shapes and layout (elbow, bar, frame, panel) | 1 | L |
| 3 | Controls and navigation | 2 | L |
| 4 | Forms and form builder | 3 | M |
| 5 | Data display | 2 | L |
| 6 | Feedback | 3 | M |
| 7 | Motion, sound, theming polish, performance | 3–6 | M |
| 8 | Packaging, generators, docs, release | all | M |
| 9 | Backlog (post-1.0) | – | – |

Phases 4, 5 and 6 can run in any order after their dependency is met.

---

## Definition of Done — every component

A component is done only when **all** of these exist and pass:

1. Ruby class + sidecar ERB template, documented params, validated inputs (clear `ArgumentError`).
2. Unit spec (`render_inline`): default render, every variant, `class:`/`data:`/`aria:` pass-through,
   invalid input, I18n strings (en + fr), slots.
3. CSS in its own file under `app/assets/stylesheets/deckplate/components/`, layer `dp.components`,
   only `--dp-*` variables and tokens (no hard-coded colours/px for shapes), works in all 5 themes.
4. Lookbook preview with: default, all variants, edge cases (long text, empty, many items, error), and a
   realistic composition.
5. Accessibility: axe clean in every theme; keyboard behaviour per SPEC §10; system spec (Cuprite) for any
   Stimulus behaviour.
6. Visual baseline images committed (3 widths × 5 themes) after human-review of the diff.
7. CSP-safe mode renders no inline `style=` (if the component takes dynamic values).
8. Turbo check: renders correctly inside a Turbo Frame and from a Turbo Stream response; survives a morph
   refresh without losing state (if stateful).
9. `bin/ci` green; coverage not lowered; budgets respected; CHANGELOG entry added.

---

## Phase 0 — Bootstrap and risk spikes

Goal: a green empty skeleton and the five technical risks answered by evidence.

**Tasks**
1. Create the gem skeleton in `~/Projects/deckplate` (already holds `CLAUDE.md` and `docs/`):
   `rails plugin new` with `--mountable`, no default test framework, dummy app at `spec/dummy`
   (check the exact flags in the current Rails guide; keep the existing files). Rename/organise to match
   SPEC §3. `git init`, `.gitignore`, MIT `LICENSE`, README stub (with disclaimer), CHANGELOG, CREDITS.
2. Gemspec: name `deckplate`, version `0.1.0.dev` (now 0.9.0, see CHANGELOG), `required_ruby_version >= 3.3`, runtime deps `rails` and
   `view_component` with verified ranges, `files` per SPEC §3, metadata (no franchise names).
3. Tooling: RSpec (rspec-rails), SimpleCov (≥ 95 %), rubocop-rails-omakase + `.rubocop.yml`, Capybara + Cuprite,
   axe-core-rspec, Lookbook, Appraisal (Rails 8.0 / 8.1). Create `bin/setup`, `bin/ci`, `bin/dev`,
   `bin/rubocop`. **[T]** a smoke spec: dummy app boots, engine is loaded, `Deckplate::VERSION` exists.
4. Dummy app: Rails 8.x with Propshaft, importmap-rails, turbo-rails, stimulus-rails, Lookbook mounted at
   `/lookbook` (development only), a layout using `dp_root`.
5. CI script `bin/ci` and a GitHub Actions workflow running it (matrix: Rails 8.0/8.1).
6. Copy the style-guide palette table (SPEC §5.2) into a machine-readable file `config/deckplate/palette.yml`
   to be the single source for CSS generation, docs and the contrast spec.

**Spikes** (each ends with an accepted ADR; keep spike code in `tmp/spikes/` and delete after the ADR)

| ID | Question | How to answer | ADR |
|---|---|---|---|
| S1 | How does an engine ship CSS, fonts and JS with Propshaft + importmap? Does tailwindcss-rails 4.x pick up engine stylesheets, and what does a host need to add? | read current docs/source of Propshaft, importmap-rails, tailwindcss-rails; build two throwaway host apps (with/without Tailwind 4); check digested font URLs resolve | 0001 |
| S2 | Elbow technique: `mask` radial-gradient vs canvas-coloured pseudo-element | implement both with the variables of SPEC §6.4; Playwright screenshots at DPR 1/1.25/1.5/2 and zoom 100–200 %; compare against reference pages (`~/Projects/LCARS-24.2/classic-standard.html`, `~/Projects/lcars/lcars/index.html`) for proportions | 0002 |
| S3 | Cascade layer order with Tailwind 4 (`theme, base, components, utilities`): can host utilities override `dp.*` without `!important` in both link orders? What prelude must the installer add? | throwaway page with both stylesheets; assertions in Playwright on computed styles | 0003 |
| S4 | Stimulus controller delivery from an engine via importmap: `pin_all_from` + `eagerLoadControllersFrom` vs explicit `registerDeckplate(application)`; works with Turbo morph; cache-busting in development | throwaway app; test connect/disconnect on Turbo visit, cache restore and morph | 0004 |
| S5 | ViewComponent 4 API in an engine: slots, sidecar assets, preview paths, test helpers; Lookbook with engine components and a theme toolbar | read v4 docs; minimal `ButtonComponent` + preview + spec | 0005 |

**Done when**: `bin/ci` green on the skeleton; `gem build` works; ADRs 0001–0005 are "accepted"; SPEC.md is
updated wherever an ADR changed a decision; `docs/QUESTIONS.md` reviewed.

---

## Phase 1 — Foundations

Goal: tokens, themes, fonts, base component, helpers, Lookbook chrome. No visible components yet beyond a
"token gallery" preview.

**Tasks**
1. `bin/build-css` + spec that fails if `deckplate.css` is stale. Layer prelude per ADR 0003. **[T]**
2. `tokens.css` generated from `config/deckplate/palette.yml` (stops + `-ink`), roles, surfaces, geometry,
   typography, motion, z-index. Colour utility classes `.dp-c-<name>` for stops and roles. **[T]** every
   palette entry produces both variables and class.
3. Five themes in `themes/*.css` (`classic azure nocturne daylight crimson`). **[T]** contrast spec: parse the
   variables, compute WCAG contrast for the pairs listed in `spec/contrast/pairs.yml` (text on canvas, ink on
   every stop, focus ring on canvas and on surfaces, line on canvas), fail with a readable table.
4. Fonts: add woff2 (Antonio regular/bold, Share Tech Mono) subsets latin + latin-ext from the official
   upstream sources, with OFL licence texts; `@font-face` rules; `dp_font_tags` preload helper. **[T]** helper
   spec; budget spec (≤ 90 KB). Update CREDITS.md.
5. `base.css` scoped to `.dp-root`; focus-ring styles; reduced-motion and forced-colors handling; screen-reader
   utility `.dp-sr-only`.
6. `Deckplate::Configuration` + `Deckplate.configure`. **[T]**
7. `Deckplate::BaseComponent` with concerns: `Colorable` (validation/resolution), `Sizeable`, `Variants` DSL,
   `html_options` merging (class merge, data/aria deep merge). **[T]** exhaustive unit specs — everything later
   builds on this; keep it small and boring.
8. Helpers: `dp_root`, `dp_theme_attrs`, `dp_color_class`, `dp_icon` (start with 12 icons: close, chevrons,
   check, alert, info, menu, search, plus, minus, sort asc/desc, external). **[T]**
9. I18n skeleton (`en.yml`, `fr.yml`) + `i18n-tasks`-style spec that every key exists in both locales.
10. Lookbook: shared preview layout (applies theme from toolbar param, `dp_root`), a **token gallery**
    preview (all stops, roles, type scale, spacing) and a **theme comparison** preview.
11. Visual testing harness `tools/visual` (Playwright): iterate over previews × themes × widths, write
    screenshots to `spec/visual/__current__`, diff against `spec/visual/__baseline__`, produce a diff report;
    wired to `bin/visual`. Baselines for the token gallery.

**Done when**: token gallery renders correctly in all themes; contrast spec green; budgets measured and
reported by `bin/ci`; base component fully tested; visual harness runs locally.

---

## Phase 2 — Shapes and layout

Goal: the signature look. This phase decides whether the library "feels right" — invest in visual review.

**Tasks** (component DoD applies to each; do them in this order)
1. `Spacer`, `Divider`, `Cap`.
2. `Bar` (horizontal/vertical, caps, segments, title, fill).
3. `Elbow` — implement the technique chosen in ADR 0002. All four corners, sizes, label slot, custom
   `width/height`. Add a **geometry preview** that overlays a grid and prints computed sizes; add Playwright
   assertions that the inner arc is transparent over a patterned background (if technique A) and that no
   seam appears at DPR 1.25/1.5.
4. `Block` (square/pill/start/end, number, align) and `Bracket`.
5. `Panel` and `PageHeader`, `Section`.
6. `Frame`: grid areas, `classic`/`double`/`minimal` variants, corner slots, container-query collapse at
   `48rem`, `fixed:` (`100dvh`) option. **[T]** system spec on 375/768/1280 widths: sidebar visible/collapsed,
   no horizontal scroll, main scrolls independently.
7. **Reference comparison**: build a "classic console" preview that reproduces the proportions of
   `~/Projects/LCARS-24.2/classic-standard.html` using only Deckplate components. Take side-by-side
   screenshots; tune the starting values of SPEC §5.4 until proportions match closely (not pixel-copying
   — proportions, spacing rhythm, corner radii). Record final values in SPEC §5.4.

**Done when**: all listed components meet the DoD; the classic console preview works in all 5 themes at
3 widths; visual baselines reviewed by a human (the agent must list the diff images for the developer to
approve before updating baselines).

---

## Phase 3 — Controls and navigation

**Tasks**
1. `Button` (all shapes/sizes/states; `<button>`, `<a>`, `button_to`; loading with `Spinner` placeholder CSS;
   flash-on-press 50 ms; ≥ 44 px targets on coarse pointers). `ButtonGroup`.
2. `Toggle` (checkbox + `role=switch`, no JS) and `Slider` + `dp-slider`.
3. `Nav` + `NavItem` (`aria-current` from `current_page?`, optional number badge), `TopNav`, `Breadcrumb`,
   `Pagination` (+ adapter examples for Pagy/Kaminari in guides, no dependency).
4. `Disclosure` (`<details>`), `Tabs` + `dp-tabs`, `Menu` + `dp-menu`, `Tooltip` + `dp-tooltip` (P1).
5. `Modal` + `dp-modal` (`<dialog>`, focus return, Esc, closes on successful Turbo submit; loads content from
   a Turbo Frame; preview of a confirm dialog and a form dialog).
6. `Keypad` is P2 — skip.

**System specs (Cuprite)**: tab keyboard navigation (arrows/Home/End), menu open/close/focus return, modal
focus management and Esc, pagination links, Turbo visit/back-button restore, morph refresh keeps tabs/menu
state sane.

**Done when**: every P0 control/navigation component meets the DoD; the sidebar nav works inside `Frame` with
mobile collapse (`dp-sidebar`).

---

## Phase 4 — Forms

**Tasks**
1. `FormField` (label, required marker + sr-only text, hint, error; correct `for`/`id`/`aria-describedby`/
   `aria-invalid`).
2. `TextInput` (types), `Textarea`, `Select`, `Checkbox`, `RadioGroup`, `Range`, `FileInput`, `DateInput`,
   `FormActions`.
3. `Deckplate::FormBuilder` with `dp_*` methods; honours `object.errors`; supports nested attributes and
   `fields_for`. **[T]** builder specs against a plain `ActiveModel` in the dummy app (no DB needed).
4. Dummy-app "profile form" page: create/edit, server-side validation, 422 re-render with Turbo, success
   redirect with Toast placeholder.
5. Guide `docs/guides/forms.md`.

**Done when**: a complete accessible form works end-to-end in the dummy app, axe clean in all themes,
labels and errors correctly associated, keyboard-only completion verified by a system spec.

---

## Phase 5 — Data display

**Tasks**
1. `Readout`, `DataList`, `StatusPill`.
2. `Table`: columns DSL, sortable header links with `aria-sort`, numeric/end alignment with tabular figures,
   footer (totals) slot, empty slot, sticky header, caption mandatory (raise if missing), zebra optional.
   Document the server-side sorting contract (the host sorts; the component only renders links/state).
3. `Progress`, `Gauge` (`role=meter`), `BarGraph` (with visually-hidden data table fallback), `Sparkline` (P1).
4. CSP-safe value mode (`csp_safe_values`): `dp-v-0…100` classes, `data-dp-value`, `dp-values` controller;
   specs asserting no `style=` attributes. Update all components that take dynamic values.
5. `Clock` + `dp-clock` (P1), `DataCascade` (P1, decorative, reduced-motion off).
6. Turbo Stream demo: a dashboard preview where a stream replaces a `Gauge`/`Readout` and values update
   without page reload (document the pattern: stable DOM ids, `turbo_stream.replace`).

**Done when**: P0 components meet the DoD; the dashboard demo works with live Turbo Stream updates;
CSP-safe mode verified.

---

## Phase 6 — Feedback

**Tasks**
1. `Alert` (roles per severity, dismissible via small controller or `<form method=dialog>` pattern).
2. `ConditionBanner` (normal/caution/critical; pulse on critical only; reduced motion neutralised).
3. `Toast` + `dp_toast_container` + `dp-toast`; Turbo Stream usage guide (`turbo_stream.append "dp-toasts"`);
   auto-dismiss pause on hover/focus; stack limit; `aria-live`.
4. `Spinner`, `Skeleton` (P1), `EmptyState`, `Callout` (P1).

**Done when**: toasts triggered from a Turbo Stream response in the dummy app are announced to assistive tech
(verify live-region markup in the specs) and dismiss correctly; critical banner has a non-motion cue.

---

## Phase 7 — Motion, sound, theming polish, performance

**Tasks**
1. Page-load cascade for `Frame` (header bar fill → sidebar slide → content fade, ~300/400/500 ms),
   opt-in via `animate: true`; button press flash; value-change flicker for `Readout` when updated by a
   Turbo Stream (CSS class toggled by a tiny controller or a `data-` hook). All off under reduced motion.
2. `dp-sound`: WebAudio synthesised beeps (3–4 original tones), opt-in config, mute toggle component, state in
   `localStorage`, never autoplay, unlock on first user gesture. **[T]** controller spec with a fake
   `AudioContext`.
3. `dp-theme` switcher component + cookie; server reads cookie in `dp_theme_attrs`. **[T]** system spec: theme
   persists across Turbo visits and reload; no flash of wrong theme.
4. Theme polish: review all components in all themes; fix contrast and hierarchy issues; `daylight` must look
   deliberate, not inverted.
5. Performance: measure CSS/JS/font budgets, remove dead CSS, verify no layout shift (CLS ≈ 0) on Frame and
   fonts (`size-adjust` fallbacks), verify `font-display` behaviour. Add the budget specs to `bin/ci`.
6. Forced-colors and high-contrast pass; zoom 200 % pass; coarse-pointer pass. Document known limitations.

**Done when**: motion/sound are opt-in and fully disableable; budgets green; accessibility pass documented in
`docs/guides/accessibility.md` with the manual checks performed (screen reader smoke test notes included).

---

## Phase 8 — Packaging, generators, documentation, release

**Tasks**
1. `rails g deckplate:install` (SPEC §7) with idempotency specs on a fixture app tree; `rails g deckplate:theme`.
2. `bin/integration`: generate throwaway apps (a) Propshaft + importmap, (b) + Tailwind 4; run installer; boot;
   render a page using Frame, Button, Table, Modal, Toast; run a headless smoke test. Include it in CI
   (nightly or on PR to main).
3. README (quickstart, screenshots from Lookbook), guides (SPEC §13), CHANGELOG, CREDITS.
4. Gallery: ship an **optional** generator `rails g deckplate:gallery` that adds a dev-only route and a
   gallery page for host apps (does not mount anything by default).
5. Versioning and release prep: `0.9.0` (feature complete) → `1.0.0` (after the legal checklist below).
   `gem build`, install the built gem into a fresh app, run the smoke test.
6. **Legal and originality checklist** (all must be true before any public release; otherwise keep the gem
   private, e.g. `gem "deckplate", path:` or a private git remote):
   - [ ] repo-wide search finds no franchise/studio/designer names or marks in code, CSS, docs, metadata,
         package files, screenshots or git history intended for publication. The dev-only files
         (`CLAUDE.md`, `docs/`) are not part of the gem but name the local reference folders: scrub or
         remove those mentions before the repository itself is made public;
         *(2026-11-17 run: the built gem, all tracked files outside the dev docs, commit messages and file names in git history: no match. Still
         to do by the owner before the repo is public: `CLAUDE.md`, `docs/PLAN.md`, `docs/SPEC.md` and `docs/adr/0002-elbow-technique.md` name the
         local reference folders; the git history carries the author's personal e-mail address.)*
   - [x] no studio assets (audio, images, logos, original typefaces) in the repo or the gem
         *(2026-11-17: the only binary files outside the screenshot baselines are the three OFL woff2 fonts; sounds are synthesised)*;
   - [x] fonts and their OFL licence files present; CREDITS.md complete *(2026-11-17)*;
   - [x] no code copied from reference projects (or licence-compliant with attribution)
         *(2026-11-17: none of the 665 lines of 45+ characters of our CSS, JS and Ruby appears verbatim in the three local reference projects)*;
   - [x] README disclaimer present *(2026-11-17)*;
   - [ ] manual screen reader smoke test done (`docs/guides/screen-reader-checklist.md`) or accepted as a documented limitation (Q-010);
   - [ ] the owner has decided (with legal advice if wanted) whether commercial use is acceptable and has
         recorded the decision in `docs/adr/`.
7. Tag, changelog, and publish only if the checklist is fully ticked and the owner approves.

**Done when**: a fresh Rails app can adopt Deckplate in under 10 minutes following only the README; all gates
in SPEC §12 are green.

---

## Phase 9 — Backlog (post-1.0, not part of the work above)

- ~~RTL support (logical corner names, mirrored frame).~~ Done: ADR 0017, `docs/guides/rtl.md`.
- Component manifest (`components.yml`) to generate ports (Django, Phoenix, plain HTML) and docs.
- ~~Design tokens export (JSON for Style Dictionary / Figma variables).~~ Done: `config/deckplate/tokens.json`, `docs/guides/design-tokens.md`.
- `Keypad`, ~~`Timeline`~~ (done: `Data::TimelineComponent`), `Tooltip` extras, richer charts, drag-and-drop-friendly lists.
- More themes; per-theme sound packs (synthesised).
- Hotwire Native considerations (touch density).
- Pilot adoption in a real application (separate repo; deliberately not part of this project).

---

## Suggested kickoff prompt for the implementing agent

> You are working in `~/Projects/deckplate`. Read `CLAUDE.md`, then `docs/SPEC.md`, then `docs/PLAN.md`.
> Start with Phase 0. Work strictly test-first, one task at a time, one commit per coherent step. Record
> ADRs for each spike, log doubts in `docs/QUESTIONS.md`, and do not start the next phase until the current
> phase's "Done when" is satisfied and `bin/ci` is green. Verify every dependency version and API against its
> current official documentation before using it. Report at the end of each phase with: what was done, the
> `bin/ci` result, open questions, and the screenshots/diffs that need my visual approval.
