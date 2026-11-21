# CLAUDE.md

Guidance for AI coding agents (Claude Code and others) working on **Deckplate**.
Read this file first, then `docs/SPEC.md` (what to build) and `docs/PLAN.md` (in what order).

## What Deckplate is

A Ruby gem (Rails engine) that gives Rails apps a themeable, accessible UI library with a retro-futuristic
"starship console" look: signature elbows, bars and pill buttons on a dark canvas, colour-coded panels,
monospaced data readouts.

- Delivered as ViewComponents + plain CSS (custom properties, cascade layers) + Stimulus controllers.
- Works with Propshaft + importmap (primary target). Tailwind CSS 4 is **optional**: Deckplate must not
  require it at runtime.
- Public name: **Deckplate**. Gem: `deckplate`. Ruby module: `Deckplate`. CSS prefix: `dp-`.
  Custom properties: `--dp-*`. Stimulus identifiers: `dp-*`. Helper prefix: `dp_`.
  Theme attribute: `data-dp-theme`. I18n scope: `deckplate.*`.

## Stack and versions

Verify every version against the official docs / RubyGems **before pinning it**; do not rely on memory.
Targets (to be confirmed in Phase 0): Ruby >= 3.3 (developer machine runs 3.3.5), Rails 8.0 and 8.1,
ViewComponent 4.x, Turbo 8 (morphing), Stimulus, Propshaft, importmap-rails, RSpec, Lookbook,
Capybara + Cuprite, axe-core-rspec, SimpleCov, RuboCop (rubocop-rails-omakase).

## Commands (create them in Phase 0; keep this list accurate)

```bash
bin/setup                 # install deps, prepare dummy app
bin/ci                    # rubocop + rspec (incl. contrast, axe a11y, stale-CSS check, budgets) + gem build (must be green before every PR)
bundle exec rspec         # full test suite
bundle exec rspec spec/components/deckplate/button_component_spec.rb   # one file
bin/rubocop               # lint (rubocop-rails-omakase, overrides in .rubocop.yml)
bin/dev                   # dummy app + Lookbook on http://localhost:3000/lookbook
bin/visual                # visual regression run (Playwright, dev-only tool under tools/visual)
bin/visual --update       # refresh baselines (review the diff images before committing!)
bin/integration           # generate throwaway Rails apps and test `rails g deckplate:install`
bin/build-css             # regenerate tokens.css from palette.yml and concatenate CSS sources into deckplate.css
bin/build-manifest        # regenerate config/deckplate/components.yml from the component classes (a spec fails when it is stale)
bin/budgets               # print CSS/JS/font sizes against the SPEC section 12 budgets
```

## Working rules

1. **Sources of truth**: `docs/SPEC.md` (design and API) and `docs/PLAN.md` (order and "done" criteria).
   When in doubt, re-read them. Do not guess.
2. **Strict TDD**: failing test first, minimal code, green, refactor. One coherent commit per step.
   Never delete or weaken a test to make it pass.
3. **One component at a time.** Do not start the next one until the per-component Definition of Done
   (PLAN.md section "Definition of Done") is fully met for the current one.
4. **Decisions are recorded.** Any non-trivial technical choice (the Phase 0 spikes especially) gets a short
   ADR in `docs/adr/NNNN-title.md` (context, options, decision, consequences).
5. **Doubts go to `docs/QUESTIONS.md`**: write the question, the safest assumption you applied, and the
   reason; then continue. Do not block on questions that have a safe default.
6. **Quality gates**: SimpleCov >= 95 % line coverage, RuboCop clean, axe has no violations on every
   preview in every theme, contrast spec green, size budgets respected (see SPEC.md section 12).
7. **No scope creep**: if a feature is not in SPEC.md, add it to the backlog section of PLAN.md instead
   of building it.
8. Ruby code style follows rubocop-rails-omakase. ERB sidecar templates for components; no Slim/Haml.
9. All user-visible strings come from I18n (`en` and `fr` provided). No hard-coded English in templates,
   except demo content in previews.
10. Components never touch the database, `current_user`, or any host-app model. They take plain values.
11. No inline `<script>`. Prefer native HTML (`<dialog>`, `<details>`, popover attribute, `<button>`) and add
    Stimulus only where behaviour requires it.

## Legal and originality guardrails (hard rules)

Deckplate is inspired by the visual language of a well-known TV franchise's computer interface, but it is an
**independent, original implementation**.

- Do **not** use the franchise's, the studio's or the designer's names or trademarks anywhere in the shipped
  product: not in gem name, module, class names, CSS classes, component names, docs headlines, metadata,
  commit messages that end up in the public history, or marketing copy. Use neutral words
  ("console", "starship-bridge style", "retro-futuristic").
  (Example: a date and time component is called `Clock`/`Timestamp`, never after a term from the franchise.)
- Do **not** ship or copy studio assets: logos, audio, images, screenshots, the original typefaces.
  Sounds are synthesised with WebAudio (original beeps). Fonts: only SIL OFL fonts (Antonio, Share Tech Mono),
  with their licence files included.
- Colour hex values and generic colour names (e.g. "neon carrot", "anakiwa") are fine.
- Code from other projects is **not copied** unless its licence allows it and attribution is added to
  `CREDITS.md`. Reference material is for studying techniques only (see "Reference material" below).
- README must carry a short non-affiliation disclaimer.
- The author is not a lawyer: before the first public release, run the legal checklist in PLAN.md Phase 8.
  Until then, treat the gem as private/internal.

## Reference material

Earlier style guides, mock-ups and small open-source libraries on the developer's machine were studied for techniques and proportions only. They are
not part of this repository, are never vendored into it, and no code, audio, font or image from them is copied. Anything reused later needs a compatible
licence and an entry in `CREDITS.md`. Names found in such material are translated to the neutral Deckplate vocabulary defined in SPEC.md.

## Repository map (target)

See SPEC.md section 3. Shipped in the gem: `app/`, `config/`, `lib/`, `LICENSE`, `README.md`, `CHANGELOG.md`,
`CREDITS.md`. Not shipped: `spec/`, `tools/`, `docs/`, `bin/` development scripts.
