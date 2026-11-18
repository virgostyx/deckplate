# Deckplate

Themeable, accessible Rails UI components with a retro-futuristic "starship console" look: signature elbows, bars and pill buttons on a dark
canvas, colour-coded panels, monospaced data readouts. ViewComponents + plain CSS (custom properties, cascade layers) + Stimulus.

> Status: pre-release (0.x), private. See the CHANGELOG.

## Quickstart

```ruby
# Gemfile (the gem is private: path or private git remote)
gem "deckplate", path: "../deckplate"
```

```bash
bundle install
bin/rails g deckplate:install      # initializer, layout wiring, Stimulus controllers; safe to run again
bin/rails g deckplate:gallery      # optional: a development-only page at /deckplate
```

```erb
<%= render Deckplate::Layout::FrameComponent.new do |f|
  f.with_header { render(Deckplate::Shapes::BarComponent.new(color: :accent, caps: :end)) { |b| b.with_title { "Engineering" } } }
  f.with_main do
    safe_join([
      render(Deckplate::Layout::PageHeaderComponent.new(title: "Overview")),
      render(Deckplate::ButtonComponent.new(label: "Engage", color: :primary))
    ])
  end
end %>
```

## Compatibility

| | |
|---|---|
| Ruby | 3.3 or newer |
| Rails | 8.0 and 8.1 |
| ViewComponent | 4.x (installed with the gem) |
| Assets and JavaScript | Propshaft + importmap, Turbo 8 (morph supported), Stimulus 3 |
| Tailwind CSS | 4, optional (the gem never needs it) |
| Browsers | current Chrome, Firefox and Safari (elbows verified on all three engines) |

## What is in it

| Family | Components |
|---|---|
| Shapes and layout | `Elbow`, `Bar`, `Block`, `Cap`, `Bracket`, `Divider`, `Spacer`; `Frame`, `PageHeader`, `Panel`, `Section` |
| Controls and navigation | `Button`, `ButtonGroup`, `Nav`, `TopNav`, `Tabs`, `Menu`, `Modal`, `Tooltip`, `Disclosure`, `Breadcrumb`, `Pagination`, `Toggle`, `Slider` |
| Forms | `FormField`, text, textarea, select, checkbox, radio group, range, date and file inputs, `FormActions`, `Keypad`, and a `Deckplate::FormBuilder` |
| Data display | `Readout`, `Table`, `DataList`, `Gauge`, `Progress`, `BarGraph`, `Sparkline`, `StatusPill`, `Clock`, `DataCascade`, `Timeline` |
| Feedback | `Alert`, `Toast` (Turbo Streams), `ConditionBanner`, `Callout`, `EmptyState`, `Skeleton`, `Spinner` |
| Extras | `ThemeSwitcher` (cookie, no flash), opt-in sound (`SoundToggle`), entrance animation (`Frame animate: true`) |

Right-to-left pages are supported (set `dir="rtl"`).

Components take plain values: they never touch the database or `current_user`. All text comes from I18n (`en` and `fr`).

## Configuration

`config/initializers/deckplate.rb` (created by the installer):

```ruby
Deckplate.configure do |c|
  c.default_theme   = :classic
  c.themes          = %i[classic azure nocturne daylight crimson verdant high-contrast]
  c.sounds          = false              # opt-in, never autoplays
  c.csp_safe_values = false              # true: no inline style attributes
  c.strict_colors   = Rails.env.local?   # raise on an unknown colour role
  c.form_builder    = false              # true: Deckplate::FormBuilder is the default builder
end
```

`bin/rails g deckplate:theme ocean` starts a custom theme from the classic mapping.

## Accessibility

axe-core runs on every component in every theme; colour contrast is checked against WCAG 2.2 AA; keyboard use, reduced motion, forced colours,
200 % and 400 % zoom and touch target size have their own specs. Information is never carried by colour or sound alone. No test with a real screen
reader has been done yet.

## Documentation

Guides are in `docs/guides/` of the repository: installation, stylesheets, Tailwind, theming, forms, data display, feedback, Turbo patterns,
motion/sound/theme switching, CSP, design tokens export (JSON), component manifest (YAML), right-to-left, accessibility, upgrading. The living component catalogue is a Lookbook (`bin/dev`, then
`http://localhost:3000/lookbook`).

## Development

`bin/setup`, then `bin/ci` (RuboCop, specs, budgets, gem build). `bin/integration` generates throwaway Rails apps (with and without Tailwind) and
smoke-tests the installer. `bin/visual` runs the screenshot regression suite. See `CLAUDE.md`, `docs/SPEC.md` and `docs/PLAN.md`.

## Disclaimer

Deckplate is an independent project. It is not affiliated with, endorsed by, or sponsored by any film or television studio, franchise, or rights
holder. The fonts (Antonio, Share Tech Mono) are under the SIL Open Font License; see `CREDITS.md`.

## Licence

MIT (see `LICENSE`).
