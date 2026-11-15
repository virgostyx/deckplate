# ADR 0004 — Delivering Stimulus controllers from the engine

Status: accepted (Phase 0, spike S4)

## Context
Options: (A) explicit `registerDeckplate(application)` exported by the engine's `deckplate` module;
(B) `pin_all_from` the controllers directory and the host calls `eagerLoadControllersFrom("deckplate/controllers", application)`.
Tested in a throwaway Rails 8.1 host (Propshaft, importmap-rails 2.2.3, turbo-rails, stimulus-rails, Tailwind) with
Chrome driven by Playwright 1.65.1 (system Chrome channel).

## Findings (identical for A and B)
- Fresh load: `connect` once. Turbo visit away: `disconnect`. Back button (Turbo cache restore): `connect` again, no
  duplicates. Morph refresh (`turbo_refreshes_with method: :morph`): the element is kept, **no** disconnect/reconnect,
  no console errors.
- Engine `config/importmap.rb` may use `pin_all_from File.expand_path("../app/javascript/deckplate/controllers", __dir__),
  under: "deckplate/controllers"`; each controller is served with its own digest and the digest changes when the
  file changes, in development too (no stale cache).
- Controller file names `dp_xxx_controller.js` map to identifier `dp-xxx` under B; under A the identifier is explicit.
- A is explicit and debuggable; B needs no host code beyond one line but registers everything and gives no control.

## Decision
- **Primary: A.** `app/javascript/deckplate/index.js` exports `registerDeckplate(application, { only, except } = {})`
  and the installer adds `import { registerDeckplate } from "deckplate"; registerDeckplate(application)` to the host's
  `controllers/index.js`. Identifiers are fixed in one table in `index.js`.
- **Also supported: B**, because the pins exist anyway; documented as an alternative. Both must keep working, so a
  spec/integration check covers both.
- All controllers: idempotent `connect`/`disconnect`, no global state.

## Consequences
- Pins: `deckplate` plus `deckplate/controllers/*` (needed by `index.js` imports as well).
- New controllers must be added to the `index.js` table (a spec compares the table with the files on disk).
- Hosts on bundlers import `deckplate` from the gem's JS path (best effort, documented later).
