# ADR 0016 — The Tailwind bridge ships by default

Status: accepted (Phase 8). Resolves the open point of ADR 0001.

## Context
`app/assets/tailwind/deckplate/engine.css` maps the Deckplate tokens to Tailwind 4 theme variables (`@theme inline`). tailwindcss-rails imports it
automatically when it exists in an engine. The question was whether to ship it or have the installer copy it into the host.

## Decision
Ship it in the gem. It contains only variable references and has no effect without Tailwind; copying it would freeze a list that must follow the
palette. `spec/tailwind_bridge_spec.rb` checks it against the token list. The installer only adds the layer prelude (ADR 0003).

## Consequences
Hosts with Tailwind get `bg-dp-primary`, `text-dp-ink`, `font-dp-display`, ... without configuration; hosts without it are unaffected.
Propshaft also lists the file as an asset (harmless).
