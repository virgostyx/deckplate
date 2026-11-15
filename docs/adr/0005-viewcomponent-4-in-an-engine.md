# ADR 0005 — ViewComponent 4 inside the engine

Status: accepted (Phase 0, spike S5)

## Context
Deckplate ships ViewComponents from an isolated Rails engine and documents them with Lookbook.
Verified against view_component 4.24.0, lookbook 2.3.15, Rails 8.1.4.1 (Ruby 3.3.5).

## Findings
- Components under `app/components/deckplate/` with a sidecar `*_component.html.erb` are autoloaded by the
  engine with no extra configuration. Slots (`renders_one`/`renders_many`) work as documented.
- **Config renames in v4**: `config.view_component.preview_paths` no longer exists, use
  `config.view_component.previews.paths` (assigning the old name raises `UnknownConfigOptionError`).
- Previews live in `spec/components/previews` and are registered **only in the dummy app**
  (`spec/dummy/config/application.rb`), so they are never shipped. The native route
  `/rails/view_components/<preview>/<scenario>` and Lookbook (`/lookbook`) both serve them.
- Specs: `require "view_component/test_helpers"`, then `config.include ViewComponent::TestHelpers, type: :component`
  and `Capybara::RSpecMatchers` (for `have_css`/`have_text` on `page`). `render_inline` yields the component to a block
  for slots.
- Lookbook theme toolbar: `config.lookbook.preview_display_options = { theme: %w[classic azure ...] }` adds a
  toolbar dropdown; the choice reaches the preview layout as `params[:_display][:theme]`.

## Decision
Use the layout above. Hand-written `html_options` merging stays in our own `BaseComponent` (Phase 1).
Use Lookbook `preview_display_options` for the theme switcher (Phase 1, task 10).

## Consequences
- Never use `preview_paths`; docs and generators must say `previews.paths`.
- The spike `ButtonComponent` was deleted; the real one is built test-first in Phase 3.
