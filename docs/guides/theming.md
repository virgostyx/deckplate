# Theming

- Built-in themes: `classic` (default), `azure`, `nocturne`, `daylight`, `crimson`. Choose with `config.themes` and `config.default_theme`.
- The theme is the `data-dp-theme` attribute on `<html>` (or any `.dp-root`): `<html <%= tag.attributes(dp_theme_attrs) %>>` reads the `dp_theme`
  cookie, so the first paint is already right. `ThemeSwitcherComponent` lets users choose (see `motion-sound-theme.md`).
- A theme is a set of CSS custom properties: ten colour roles with their `-ink` text colours (`--dp-primary`, `--dp-primary-ink`, ...), then `--dp-canvas`,
  `--dp-surface`, `--dp-surface-raised`, `--dp-ink`, `--dp-ink-muted`, `--dp-line`, `--dp-focus`, `--dp-disabled`.
- To add one, define `[data-dp-theme="mine"] { ... }` in the `dp.tokens` layer with all of them, add `"mine"` to `config.themes`, and run the contrast
  spec pattern from `spec/contrast` on your pairs (ink on role, role on canvas >= AA).
- Components take a colour role (`color: :primary`), never a hex value. Unknown roles raise in development and test (`config.strict_colors`).
