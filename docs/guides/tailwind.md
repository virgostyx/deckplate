# Tailwind CSS 4 (optional)

Deckplate does not need Tailwind and its components never use utility classes. If your host uses Tailwind 4, two things matter.

## Layer order
Tailwind utilities must override Deckplate components, and Deckplate must override Tailwind's preflight reset (buttons, headings, lists).
Cascade layers decide this, and the first `@layer` statement that names the layers wins. `rails g deckplate:install` puts this line first in
`app/assets/tailwind/application.css`:

```css
@layer theme, base, dp, components, utilities;
```

Every Deckplate stylesheet starts with the same line, so the link order of the stylesheets then does not matter. Without the line, link Deckplate
before Tailwind. (ADR 0003; checked by `bin/integration` on a real Tailwind host app.)

## The bridge: Deckplate colours as utilities
The installer copies `app/assets/tailwind/deckplate-bridge.css` and imports it after `@import "tailwindcss";`. It exposes the tokens as theme
variables: `bg-dp-primary`, `text-dp-primary-ink`, `border-dp-line`, `font-dp-display`, `font-dp-data`. They are live CSS variables, so they
follow the active theme. After upgrading Deckplate, delete the copied file and run the installer again to refresh it.

## Class names
Tailwind scans your views for class names. Deckplate's own markup needs no scanning.
