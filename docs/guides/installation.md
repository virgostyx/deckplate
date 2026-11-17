# Installation

## Requirements
Ruby 3.3 or newer, Rails 8.0 or 8.1, Propshaft and importmap-rails (the default Rails 8 setup), Stimulus and Turbo (included in a default app).
ViewComponent 4 is installed with the gem. Tailwind CSS 4 is optional (see `tailwind.md`).

## Add the gem
Deckplate is private for now. Use a path or a private git remote:

```ruby
gem "deckplate", path: "../deckplate"
# or: gem "deckplate", git: "git@your-host:you/deckplate.git"
```

Then `bundle install`.

## Run the installer
```bash
bin/rails g deckplate:install
```
It is safe to run again. It:
1. creates `config/initializers/deckplate.rb` (every option with its default; never overwritten);
2. patches `app/views/layouts/application.html.erb`: `dp_font_tags` and `stylesheet_link_tag "deckplate"` before your own stylesheet,
   `<%= tag.attributes(dp_theme_attrs) %>` on `<html>`, `class="dp-root"` on `<body>`;
3. registers the Stimulus controllers in `app/javascript/controllers/index.js` (`registerDeckplate(application)`);
4. with Tailwind: adds the layer prelude and the bridge import (see `tailwind.md`).

When a file cannot be patched safely (ERB inside `<html>` or `<body>`, no layout, no importmap) the installer changes nothing in it and prints the
exact lines to add. Do those by hand.

## Check it works
```erb
<%= render Deckplate::ButtonComponent.new(label: "Engage") %>
```
Optional: `bin/rails g deckplate:gallery` adds a development-only page at `/deckplate` showing the components in your layout and themes.

## Toasts
Put `<%= dp_toast_container %>` once in the layout, inside the body (see `feedback.md`).

## Bundler-based JavaScript (esbuild, Vite, ...)
Not supported yet: the controllers are served through importmap. The CSS and the components work in any setup.

## Removing it
Delete the gem line, the initializer, the lines the installer added to the layout and `controllers/index.js`, and (Tailwind) the prelude, the import
and `app/assets/tailwind/deckplate-bridge.css`.
