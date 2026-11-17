# ADR 0001 — Shipping CSS, fonts and JS from the engine

Status: accepted (Phase 0, spike S1)

## Context
Deckplate must deliver one stylesheet, woff2 fonts and Stimulus controllers to hosts using Propshaft + importmap-rails,
with or without Tailwind 4. Verified with Rails 8.1.4.1, propshaft 1.3.2, importmap-rails 2.2.3,
tailwindcss-rails 4.7.0 (Tailwind 4.3.4), using the dummy app and a throwaway Tailwind host app.

## Findings
- **Propshaft adds every `app/assets/*` subdirectory of an engine to the load path** automatically
  (`stylesheets/`, `fonts/`). `deckplate.css` and `deckplate/<font>.woff2` resolve with digests, and Propshaft rewrites
  `url("deckplate/x.woff2")` in CSS to `/assets/deckplate/x-<digest>.woff2` (served, HTTP 200). No `@import` handling
  or extra config needed.
- **`app/javascript` is NOT on the asset path for engines.** The engine must add it:
  `app.config.assets.paths << root.join("app/javascript")`, and register its pins:
  `app.config.importmap.paths << root.join("config/importmap.rb")` plus
  `app.config.importmap.cache_sweepers << root.join("app/javascript")` (initializer `before: "importmap"`).
  Then `pin "deckplate", to: "deckplate/index.js"` appears in the host importmap and the file is served.
- **`stylesheet_link_tag :app` does not include the engine's stylesheet**; the host layout needs an explicit
  `stylesheet_link_tag "deckplate"` (the installer adds it; `dp_*` helper may wrap it later).
- **tailwindcss-rails 4.x only touches engines that ship `app/assets/tailwind/<engine_name>/engine.css`**
  (`Tailwindcss::Engines.bundle` generates an `@import` of that file into the host build). Our plain CSS is untouched by
  Tailwind and keeps working alongside it. Tailwind never needs to scan our markup.

## Decision
1. Plain CSS bundle `app/assets/stylesheets/deckplate.css`, fonts in `app/assets/fonts/deckplate/`, linked explicitly.
2. Engine initializers (assets path + importmap paths/sweeper) guarded by `respond_to?(:assets / :importmap)`
   so hosts on other pipelines don't crash.
3. The optional Tailwind bridge ships as `app/assets/tailwind/deckplate/engine.css` (contains only the
   `@theme inline` mapping). It is picked up by tailwindcss-rails with no host config, but only affects hosts that use
   Tailwind. *(Superseded by ADR 0016: the installer copies the bridge; tailwindcss-rails does not import engine CSS by itself.)*

## Consequences
- The installer must add the stylesheet link and, for importmap hosts, rely on the engine's pins.
- Sprockets / bundler pipelines are best effort (not tested here).
- Fonts must be referenced relative to the stylesheet (`deckplate/<file>`) so digests resolve.
