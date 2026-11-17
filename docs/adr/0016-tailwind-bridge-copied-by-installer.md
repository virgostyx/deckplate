# ADR 0016 — The Tailwind bridge is copied by the installer

Status: accepted (Phase 8). Resolves the open point of ADR 0001 and corrects one of its claims.

## Context
The bridge maps Deckplate tokens to Tailwind 4 theme variables (`@theme inline`: `bg-dp-primary`, `text-dp-ink`, `font-dp-display`).
ADR 0001 expected tailwindcss-rails to pick up `app/assets/tailwind/deckplate/engine.css` without host config. `bin/integration` (Tailwind
variant, tailwindcss-rails 4.7.0) showed otherwise:
- the gem only writes `app/assets/builds/tailwind/deckplate.css` (an `@import` of the engine file by **absolute path**); the host must import it itself;
- that generated file is also an asset, linked by Rails' `stylesheet_link_tag :app`, so the browser requested the absolute path and got a 404;
- the engines feature is documented as experimental.

## Options
1. Ship `engine.css` and make the installer add `@import "../builds/tailwind/deckplate"` (keeps the 404 and the experimental feature).
2. Do not use the engines feature: the installer copies the bridge into the host and imports it.

## Decision
Option 2. The bridge is a template of the installer (`lib/generators/deckplate/install/templates/tailwind_bridge.css`), copied to
`app/assets/tailwind/deckplate-bridge.css` (never overwritten) and imported by `app/assets/tailwind/application.css` right after
`@import "tailwindcss";`, next to the layer prelude of ADR 0003. `spec/tailwind_bridge_spec.rb` checks it against the token list.

## Consequences
- No `app/assets/tailwind` directory in the gem. The copy can drift from the token list after an upgrade: delete the copied file and re-run the installer.
- Hosts without Tailwind are unaffected.
