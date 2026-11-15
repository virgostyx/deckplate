# Deckplate — Specification

Status: draft v1 (written before implementation; update it when an ADR changes a decision).
Audience: the AI agent (or human) implementing the gem. Everything here is normative unless marked *(spike)*,
which means "decide in Phase 0 and record an ADR".

---

## 1. Vision, scope, non-goals

**Vision.** A Rails engine gem so that any Rails app can build screens that look and feel like a starship
console — elbows, bars, pill buttons, colour-coded blocks on a black canvas — using reusable ViewComponents,
without writing bespoke CSS.

**In scope (v1.0)**
- Design tokens (colour roles, named palette, typography, geometry, motion) and 5 themes.
- Shape primitives (elbow, bar, block, cap, bracket, divider) and the page frame layout.
- ~45 ViewComponents (section 8), a form builder, Stimulus controllers, view helpers.
- Install/theme generators, I18n (en, fr), Lookbook documentation, tests, visual regression, accessibility.

**Non-goals (v1.0)**
- No dependency on Tailwind, Bootstrap, jQuery or any JS framework. (Optional Tailwind bridge only.)
- No right-to-left support (backlog). No Django/other-framework port (backlog; share a component manifest later).
- No charts library: only lightweight server-rendered gauges, bar graphs, sparklines.
- No studio assets, no franchise names (see CLAUDE.md legal rules).
- No hosted CDN build. The gem is the distribution.

---

## 2. Compatibility matrix

| Layer | Target | Notes |
|---|---|---|
| Ruby | >= 3.3 | CI also on latest stable |
| Rails | 8.0 and 8.1 | Appraisal gemfiles for both. Rails 8.0 needs `json < 3` (it passes `quirks_mode` to `JSON.generate`; fixed in 8.1); a host on 8.0 must pin it too |
| ViewComponent | 4.x | read the v4 docs first (slots, previews, test helpers) |
| Assets | Propshaft + importmap-rails | primary, fully supported |
| Other pipelines | Sprockets / jsbundling / cssbundling | best effort, documented, not CI-gated in v1.0 |
| JS | Stimulus 3, Turbo 8 | morph refreshes must work (`turbo_refreshes_with method: :morph`) |
| Browsers | evergreen Chrome, Firefox, Safari, Edge (last 2 versions) | uses cascade layers, `@container`, `mask`, `popover`, `<dialog>` |
| Tailwind | 4.x optional | coexistence tested in `bin/integration` |
| CSP | strict CSP supported | see section 11 |

---

## 3. Repository layout (target)

```
deckplate/
├── CLAUDE.md  README.md  CHANGELOG.md  CREDITS.md  LICENSE (MIT)  Gemfile  deckplate.gemspec  Rakefile
├── Appraisals  .rubocop.yml  .rspec  .gitignore
├── bin/ setup ci dev rubocop build-css visual integration
├── app/
│   ├── components/deckplate/            # Ruby + sidecar .html.erb, one folder per family
│   │   ├── base_component.rb  concerns/ (colorable, sizeable, variants)
│   │   ├── shapes/ layout/ controls/ navigation/ forms/ data/ feedback/
│   ├── helpers/deckplate/               # dp_theme_attrs, dp_root, dp_font_tags, dp_toast_container ...
│   ├── assets/
│   │   ├── stylesheets/deckplate/       # SOURCE css (tokens, themes, base, shapes, layout, components/*)
│   │   ├── stylesheets/deckplate.css    # GENERATED bundle (committed; built by bin/build-css)
│   │   ├── stylesheets/deckplate/tailwind-bridge.css   # optional @theme mapping
│   │   └── fonts/deckplate/             # woff2 + OFL licence files
│   └── javascript/deckplate/
│       ├── index.js                     # registers controllers
│       └── controllers/                 # dp-*_controller.js
├── config/
│   ├── importmap.rb                     # pins for the host's importmap
│   └── locales/ en.yml fr.yml
├── lib/
│   ├── deckplate.rb  deckplate/version.rb  deckplate/engine.rb  deckplate/configuration.rb
│   ├── deckplate/form_builder.rb
│   └── generators/deckplate/ install/ theme/ (templates inside)
├── docs/ SPEC.md PLAN.md QUESTIONS.md adr/ guides/
├── spec/
│   ├── dummy/                           # Rails 8.x app: propshaft + importmap + turbo + stimulus + lookbook
│   ├── components/ (specs)  components/previews/ (Lookbook previews)
│   ├── system/ (Cuprite)  a11y/  contrast/  generators/  support/  visual/
└── tools/visual/                        # Node + Playwright, dev-only (not shipped)
```

Gemspec `files` includes only `app/ config/ lib/ LICENSE README.md CHANGELOG.md CREDITS.md`.

---

## 4. Naming and API conventions

- Ruby: `Deckplate::ButtonComponent`, `Deckplate::Forms::TextInputComponent`, etc. Zeitwerk-friendly.
- CSS: BEM-like with prefix — `.dp-elbow`, `.dp-elbow--top-left`, `.dp-elbow__label`. Never style bare elements
  outside `.dp-root` scope (section 6.3).
- Custom properties: `--dp-*` only. Component-level knobs are documented (e.g. `--dp-elbow-col`).
- Stimulus identifiers: `dp-tabs`, `dp-modal`, ... Targets/values/classes follow Stimulus naming.
- Colours are passed as Symbols: a **role** (`:primary, :secondary, :tertiary, :accent, :muted, :info,
  :success, :warning, :danger, :emergency`) or a **palette stop** (`:neon_carrot`). Underscores in Ruby,
  hyphens in CSS. Invalid values raise `ArgumentError` listing valid ones (dev/test) and fall back to
  `:primary` with a log warning (production).
- Every component accepts `**html_options`: `class:` is merged (never replaced), `data:`/`aria:` are
  deep-merged, `id:` passes through.
- Variants are declared with a small DSL (`variant :size, %i[sm md lg], default: :md`) that generates
  modifier classes (`dp-button--lg`). Full class strings, never string-interpolated class fragments
  built from user input.
- Slots use ViewComponent slots (`renders_one :label`, `renders_many :items`). Public API is Ruby kwargs +
  slots only; no positional args beyond the main content.
- Units: sizes given as numbers are multiples of the layout unit `--dp-u` (section 5.4).
- Components are render-pure: same inputs, same HTML. No randomness, no time, except `Clock`
  (JS-updated) which renders a server timestamp as its initial value.
- Domain-neutral demo data in previews (ships, no accounting, no host-app concepts).

---

## 5. Design tokens

### 5.1 Colour architecture

Three tiers, all CSS custom properties on `:root` / `[data-dp-theme]`:

1. **Palette stops** `--dp-<stop>` (raw colours, theme-independent names). Each stop also has
   `--dp-<stop>-ink` (readable text colour on that stop; usually `#000`, light for dark stops).
2. **Semantic roles** `--dp-primary`, `--dp-secondary`, `--dp-tertiary`, `--dp-accent`, `--dp-muted`,
   `--dp-info`, `--dp-success`, `--dp-warning`, `--dp-danger`, `--dp-emergency`, plus `-ink` variants.
   Themes remap roles to stops.
3. **Surfaces and text**: `--dp-canvas` (page, default `#000`), `--dp-surface` (panel interior),
   `--dp-surface-raised`, `--dp-ink` (text on canvas), `--dp-ink-muted`, `--dp-line` (hairlines),
   `--dp-focus` (focus ring), `--dp-disabled`.

A single "current colour" variable drives every coloured element: modifier class `.dp-c-<name>` sets
`--dp-c: var(--dp-<name>)` and `--dp-c-ink: var(--dp-<name>-ink)`; shapes paint with `background: var(--dp-c)`
and `color: var(--dp-c-ink)`. This avoids generating bg/text class pairs per colour.
*(Future: replace per-stop ink tokens with `contrast-color()` once baseline-supported; ADR when revisited.)*

### 5.2 Palette stops (starting table — port from the author's style guide §2.1, with fixes)

Source: `~/Projects/LCARS_styleguide/LCARS_STYLE_GUIDE.md` §2.1. Port the hex values; **apply these corrections**:
- `atomic-tangerine` and `sandy-brown` are both `#FF9966` → keep one stop (`atomic-tangerine`).
- Rename `red-alert` (`#FF0000`) to `signal-red` (neutral vocabulary; not `emergency`, which is a *role* name and would make
  `--dp-emergency: var(--dp-emergency)` a cycle).
- Phase 1 added extension stops: `fern`, `forest` (greens, Q-003), `copper`, `ochre`, `plum`, `violet`, `steel`, `garnet`, `slate`
  (darker hues so `daylight` meets contrast).
- `navy-blue` (`#000099`) fails contrast on black: mark **background-only**, never use for text/lines on canvas.
- Add `-ink` for every stop; verify by the contrast spec.

Stops (hex): pale-canary FFFF99 · golden-tanoi FFCC66 · neon-carrot FF9933 · atomic-tangerine FF9966 ·
orange-peel FF9900 · hopbush CC6699 · chestnut-rose CC6666 · red-damask CC6644 · medium-carmine CC3333 ·
signal-red FF0000 · anakiwa 99CCFF · periwinkle CCCCFF · blue-bell 9999CC · melrose 9999FF · mariner 4466AA ·
danub 6688CC · dodger-blue 4499FF · indigo 336699 · bahama-blue 006699 · navy-blue 000099 (bg only) ·
lilac CC99CC · lavender-purple 9966CC · cosmic 774466 · eggplant 330066 · husk BB9944 · bourbon BB6633 ·
rust 883311 · tamarillo 882211 · white FFFFFF · gray 999999.

### 5.3 Semantic mapping (theme `classic`)

| Role | Stop | Used for |
|---|---|---|
| primary | neon-carrot | main actions, primary bars |
| secondary | golden-tanoi | section titles, secondary blocks |
| tertiary | hopbush | navigation blocks |
| accent | lilac | decorative accents, profile/identity blocks |
| muted | blue-bell | disabled / passive structure |
| info | anakiwa | information, links, data panels |
| success | pale-canary | OK states (themes may remap to green) |
| warning | orange-peel | non-critical warnings |
| danger | chestnut-rose | errors, destructive actions |
| emergency | emergency | condition banner only; use sparingly |

**Rule: colour is never the only carrier of meaning.** Status always has text and/or an icon/shape.

### 5.4 Geometry and typography

- Layout unit `--dp-u: 1.375rem` (≈22 px at 16 px root). Everything in `rem`/`em`/`u`; never `px` for shapes,
  so zoom and root font-size changes scale the whole console.
- **Final values (Phase 2, tuned against a classic console page at 1280x800, u = 22px; proportions matched, not copied)**:
  bar thickness `--dp-bar: 0.9 u` (reference 20px), gap `--dp-gap: 0.35 u` (8px), elbow column `--dp-elbow-col: 8 u`
  (180px), elbow outer radius `--dp-elbow-r: 4.5 u` (100px), elbow inner radius `--dp-elbow-ri: 1.8 u` (~40px),
  pill radius `9999px`, min touch target `2.75rem`. Pill blocks 8.18 u x 3 u. Previous starting values were
  bar 1.25 u, gap 0.25 u, column 6 u, r 3 u, ri 1.5 u. Side-by-side check: `Reference / Classic console` preview.
- Fonts (self-hosted woff2, SIL OFL, licence files included, `font-display: swap`, latin + latin-ext
  because French/Dutch accents are required): display/labels **Antonio** (uppercase, letter-spacing), data
  **Share Tech Mono** (tabular figures), running text falls back to `--dp-font-text: ui-sans-serif,
  system-ui, sans-serif` for readability. Host apps can override the three `--dp-font-*` variables.
- Motion: durations `--dp-t-fast: 100ms`, `--dp-t-base: 200ms`, `--dp-t-slow: 400ms`; easing snappy.
  All animation disabled/neutralised under `prefers-reduced-motion: reduce` (section 10).
- Z-index scale: `--dp-z-sticky 10`, `--dp-z-overlay 100`, `--dp-z-modal 200`, `--dp-z-toast 300`.

### 5.5 Themes (v1.0)

| Theme | Intent |
|---|---|
| `classic` | warm amber/lilac/blue on black (default) |
| `azure` | cool blues and violets |
| `nocturne` | dimmed, low-luminance, for night use |
| `daylight` | **light** variant: pale canvas, dark ink, still shape-faithful; for print and bright rooms |
| `crimson` | alert-state theme (reds); also used by `ConditionBanner` when `condition: :critical` |

Themes only change variables. Selection: `data-dp-theme="classic"` on `<html>` or any subtree
(nested themes allowed). A cookie (`dp_theme`) lets the server render the correct theme on first paint,
avoiding flash. Generator `rails g deckplate:theme NAME` scaffolds a theme file and a contrast test entry.

---

## 6. CSS architecture

### 6.1 Plain CSS, no preprocessor

Source files in `app/assets/stylesheets/deckplate/` (tokens, themes/*, base, shapes, layout, components/*).
`bin/build-css` concatenates them in a fixed order into `deckplate.css` (committed, so consumers need no
build step and Propshaft needs no `@import` resolution). A spec fails if the committed bundle is stale.
A `.min` variant is not shipped (gzip at the web server is enough).

### 6.2 Cascade layers

```css
@layer theme, base, dp, components, utilities;   /* prelude, see ADR 0003 */
@layer dp.tokens, dp.base, dp.shapes, dp.layout, dp.components, dp.states;
```
Intent: host utilities (including Tailwind's `utilities` layer) can override Deckplate without `!important`.
Verified in spike S3 (ADR 0003): the prelude must also be added to the Tailwind source by the installer.

### 6.3 Scoping

Nothing global leaks into the host. Base styles (box-sizing, colours, fonts) apply only inside `.dp-root`
(the `dp_root` helper / `<body class="dp-root">`). Components outside a `.dp-root` still work because every
component sets what it needs on its own root element, but only `.dp-root` gets canvas colour and font
defaults.

### 6.4 Shape technique *(spike S2)*

All shapes are single elements driven by variables; no images, no absolute pixel positioning, no SVG
required.

**Elbow** = a coloured block with an **outer arc** (`border-radius` on one corner) and a **transparent inner
arc** cut-out. Candidates:
- (A) `mask-image` with `radial-gradient` for the inner arc → truly transparent, works over any
  background/gradient/theme. **Preferred.**
- (B) black/canvas-coloured pseudo-element carving the inner arc (the technique used by the reference
  projects) → needs `--dp-canvas` to equal the background behind it.
Decided in ADR 0002 (technique A with a 1px overlapping fillet tile). Original wording: decide by Playwright screenshots at device pixel ratios 1, 1.25, 1.5, 2 and browser zoom 100–200 %:
no hairline seams, no overdraw, identical result in Chrome/Firefox/Safari. Record in ADR 0002.

Variables: `--dp-elbow-w`, `--dp-elbow-h` (overall), `--dp-elbow-col` (vertical arm thickness),
`--dp-elbow-bar` (horizontal arm thickness), `--dp-elbow-r`, `--dp-elbow-ri`.
Corners: `top-left | top-right | bottom-left | bottom-right` (physical names; RTL is a non-goal).

**Bar**: horizontal/vertical, optional end caps (`start`, `end`, `both`), optional segments (several coloured
blocks sharing one row), title slot, `fill` behaviour (flex-grow).
**Block**: rectangular labelled element, optional number, alignment, rounded start/end/both.
**Cap**: half-pill end piece. **Bracket**: open frame around content (`sides:` top/bottom/start/end).
**Divider**: segmented rule. **Spacer**: transparent gap in `u`.

### 6.5 Frame layout

CSS grid with named areas; container queries (`container-type: inline-size` on the frame) for responsiveness.

```
┌────────┬───────────────────────────────┬─────┐
│ elbow  │ header bar (title, actions)    │ cap │
├────────┼───────────────────────────────┴─────┤
│ side   │ main                                 │
│ nav    │                                      │
├────────┼───────────────────────────────┬─────┤
│ elbow  │ footer bar                     │ cap │
└────────┴───────────────────────────────┴─────┘
```
Variants: `:classic` (sidebar left), `:double` (sidebars both sides), `:minimal` (header bar only).
Below `48rem` container width the sidebar collapses into a header menu (native `<dialog>`/popover) and elbows
shrink to caps. `main` scrolls; frame chrome stays fixed (`height: 100dvh` option).

---

## 7. Rails integration

**Engine**: `Deckplate::Engine` with `isolate_namespace Deckplate`; no routes, no migrations, no models.
Initializers must:
- add `app/javascript` to the asset paths (`app.config.assets.paths <<`; Propshaft already adds `app/assets/*` subdirs of engines; ADR 0001);
- expose importmap pins: engine `config/importmap.rb` + `config.importmap.paths <<` and `cache_sweepers <<` (ADR 0001, 0004);
- register ViewComponent preview paths (`config.view_component.previews.paths`, v4 name) only in the dummy app (previews are not shipped; ADR 0005);
- load `config/locales/*.yml`;
- include `Deckplate::Helpers` in `ActionView::Base` via `ActiveSupport.on_load(:action_view)`.

**Configuration** (`config/initializers/deckplate.rb`, created by the installer):
```ruby
Deckplate.configure do |c|
  c.default_theme   = :classic
  c.themes          = %i[classic azure nocturne daylight crimson]
  c.sounds          = false       # opt-in, never autoplay
  c.csp_safe_values = false       # true => no inline style attributes (section 11)
  c.strict_colors   = Rails.env.local?   # raise on unknown colours
  c.form_builder    = false       # true => set as default form builder
end
```

**Install generator** `rails g deckplate:install` (idempotent; prints a summary):
1. creates the initializer;
2. adds `javascript_import_tag`-compatible pin and registers controllers in `app/javascript/controllers/index.js`
   (detects importmap vs bundler, and Stimulus presence);
3. adds `stylesheet_link_tag "deckplate"` to the layout and `dp_root`/`dp_theme_attrs` to `<html>/<body>`
   (only if the layout file can be patched safely; otherwise prints exact instructions);
4. if Tailwind 4 is detected, adds the layer prelude / bridge import per ADR 0003;
5. adds font preload tags helper usage.

**Tailwind bridge (optional)** (shipped as `app/assets/tailwind/deckplate/engine.css` so tailwindcss-rails picks it up; ADR 0001): `tailwind-bridge.css` declares `@theme inline { --color-dp-primary:
var(--dp-primary); ... }` so hosts get `bg-dp-primary`, `text-dp-ink`, etc. Components never rely on
Tailwind classes, so utility detection (`@source`) is not an issue for the gem's own markup.

**Helpers** (`Deckplate::Helpers`): `dp_root(**opts, &block)`, `dp_theme_attrs`, `dp_font_tags`
(preload), `dp_toast_container`, `dp_icon(name)` (small inline SVG set, `aria-hidden` by default),
`dp_color_class(color)`.

**Form builder**: `Deckplate::FormBuilder < ActionView::Helpers::FormBuilder` — use with
`form_with model:, builder: Deckplate::FormBuilder` or set globally via config. Methods: `dp_text_field`,
`dp_email_field`, `dp_password_field`, `dp_number_field`, `dp_text_area`, `dp_select`, `dp_check_box`,
`dp_radio_group`, `dp_range`, `dp_file_field`, `dp_date_field`, `dp_submit`. Each renders a `FormField`
(label, hint, error from `object.errors`). Turbo-friendly: invalid submissions re-render with 422.

---

## 8. Component catalogue

Priority: **P0** = required for v1.0, **P1** = nice-to-have (ship if time allows), **P2** = backlog.
Class names follow section 4. "Stim" = Stimulus controller needed.

### 8.1 Shapes and layout (`Deckplate::Shapes::*`, `Deckplate::Layout::*`)

| Component | Params (kwargs) | Slots | Notes | Pri |
|---|---|---|---|---|
| `Elbow` | `corner:`, `color:`, `size:` (:sm :md :lg) or `width:`/`height:` (u) | `label` | decorative by default (`aria-hidden`) unless label given | P0 |
| `Bar` | `orientation:` (:horizontal :vertical), `color:`, `caps:` (:none :start :end :both), `thickness:` | `title`, `segments` (many) | `fill:` grows in flex/grid | P0 |
| `Block` | `color:`, `shape:` (:square :pill :start :end), `number:`, `align:` | content | building block for nav, readouts | P0 |
| `Cap` | `side:`, `color:` | – | half-pill end | P0 |
| `Bracket` | `sides:`, `color:` | content | open frame | P1 |
| `Divider` | `color:`, `segments:` | – | segmented rule | P0 |
| `Spacer` | `size:` (u) | – | transparent gap | P0 |
| `Frame` | `variant:` (:classic :double :minimal), `theme:`, `fixed:` | `header`, `sidebar`, `aside`, `main`, `footer`, `top_left_corner`, `bottom_left_corner` | page layout, container-query responsive | P0 |
| `Panel` | `title:`, `color:`, `corners:` (none/left/both) | `header_actions`, `footer`, body | grouped content | P0 |
| `PageHeader` | `title:`, `subtitle:` | `actions`, `breadcrumb` | | P0 |
| `Section` | `title:`, `color:` | body | titled block inside Panel | P1 |

### 8.2 Controls and navigation

| Component | Key params | Stim | Notes | Pri |
|---|---|---|---|---|
| `Button` | `label:`, `color:`, `shape:` (:pill :block :start :end), `size:` (:xs..:xl), `type:`, `href:` (renders `<a>`), `method:` (via `button_to`), `icon:`, `loading:`, `disabled:` | – | min target 44 px, flash on press (50 ms) | P0 |
| `ButtonGroup` | `orientation:` | – | stacked pill/block rows | P0 |
| `Toggle` | `name:`, `checked:`, `label:` | – | `<input type=checkbox role=switch>`, no JS | P0 |
| `Slider` | `name:`, `min/max/step`, `value:`, `show_value:` | `dp-slider` (value readout) | native range | P0 |
| `Keypad` | `keys:`, `columns:` | `dp-keypad` | grid of buttons, emits events | P2 |
| `Nav` (sidebar) | `current:` auto via `current_page?` | slot `items` → `NavItem(label, href, color, number)` | `<nav aria-label>`; `aria-current="page"` | P0 |
| `TopNav` | `items` | – | secondary tab-like links | P0 |
| `Tabs` | `selected:` | `dp-tabs` | APG tabs pattern: arrows, Home/End, `aria-selected`; panels lazy via Turbo Frame optional | P0 |
| `Breadcrumb` | `items:` | – | `<nav aria-label=breadcrumb>`, `aria-current` | P0 |
| `Pagination` | `page:`, `pages:`, `url_for:` lambda | – | compatible with Pagy/Kaminari via thin adapters (no hard dependency) | P0 |
| `Menu` | `label:` (trigger) | `dp-menu` | popover attribute + menu button APG pattern | P0 |
| `Disclosure` | `summary:` | – | `<details>` | P0 |
| `Tooltip` | `text:` | `dp-tooltip` | popover/hover/focus; never essential info | P1 |
| `Modal` | `title:`, `size:`, `open:` | `dp-modal` | native `<dialog>`, focus trap via `showModal()`, Esc, return focus; works with Turbo Frame content | P0 |

### 8.3 Forms (`Deckplate::Forms::*`)

| Component | Notes | Pri |
|---|---|---|
| `FormField` | label (required marker + `sr-only` text), hint (`aria-describedby`), error (`aria-invalid`, `role=alert` on first error) | P0 |
| `TextInput` (text/email/password/number/search/tel/url), `Textarea`, `Select` (native, styled), `Checkbox`, `RadioGroup` (`<fieldset><legend>`), `Range`, `FileInput`, `DateInput` (native) | all use native elements; styling via custom properties | P0 |
| `FormActions` | submit/cancel row | P0 |
| `InlineField` | compact label+control for dense screens | P1 |

### 8.4 Data display (`Deckplate::Data::*`)

| Component | Params | Notes | Pri |
|---|---|---|---|
| `Readout` | `label:`, `value:`, `unit:`, `trend:`, `color:` | monospace, tabular, right-aligned numerics; sign never colour-only | P0 |
| `DataList` | `items:` or slots | `<dl>` key/value panel | P0 |
| `Table` | `rows:`, `caption:`, `sort:`, `dir:`, `sort_url:`, columns via `with_column(key, header:, sortable:, align:, numeric:) { \|row\| ... }`, `footer` slot (totals row), `empty:` slot | real `<table>`, `scope=col`, sticky header option, sortable headers are links with `aria-sort`; no client-side sorting in v1 | P0 |
| `StatusPill` | `status:` (:ok :warn :fail :idle ...), `label:` | text always present + shape/icon | P0 |
| `Gauge` | `value:` (0-100), `variant:` (:radial :semicircle), `label:` | pure CSS (`conic-gradient`), `role=meter` with `aria-valuenow` | P0 |
| `BarGraph` | `series:` (label, value), `max:`, `orientation:` | CSS heights from variables; includes visually-hidden data table fallback | P0 |
| `Progress` | `value:`, `segments:` | `role=progressbar`; segmented style | P0 |
| `Sparkline` | `points:`, `color:` | server-rendered inline SVG polyline, `role=img` + `aria-label` summary | P1 |
| `DataCascade` | `rows:`, `columns:` | decorative animated numbers, `aria-hidden`, disabled under reduced motion | P1 |
| `Clock` | `time:`, `format:`, `zone:` | `dp-clock` updates every second; initial value server-rendered; `data-turbo-permanent` friendly | P1 |
| `Timeline` | – | | P2 |

### 8.5 Feedback

| Component | Notes | Pri |
|---|---|---|
| `Alert` | `kind:` (:info :success :warning :danger), `dismissible:`; `role=status` (info/success) or `role=alert` (warning/danger) | P0 |
| `ConditionBanner` | `condition:` (:normal :caution :critical); pulse animation only when `critical`, off under reduced motion; always has text | P0 |
| `Toast` + `dp_toast_container` | Turbo Stream target `dp-toasts`; `dp-toast` auto-dismiss (pause on hover/focus); `aria-live=polite` | P0 |
| `Spinner` | segmented bars loader; `role=status` + sr-only text | P0 |
| `Skeleton` | placeholder blocks | P1 |
| `EmptyState` | title, hint, action slot | P0 |
| `Callout` | highlighted note inside content | P1 |

### 8.6 Example APIs (normative style)

```erb
<%= render Deckplate::Layout::FrameComponent.new(variant: :classic) do |f| %>
  <% f.with_top_left_corner { render Deckplate::Shapes::ElbowComponent.new(corner: :top_left, color: :primary) } %>
  <% f.with_header { render Deckplate::Layout::PageHeaderComponent.new(title: t(".title")) } %>
  <% f.with_sidebar do %>
    <%= render Deckplate::NavComponent.new do |n| %>
      <% n.with_item(label: "Overview", href: root_path, color: :tertiary, number: "01") %>
    <% end %>
  <% end %>
  <% f.with_main { yield } %>
<% end %>

<%= render Deckplate::ButtonComponent.new(label: "Engage", color: :primary, shape: :pill, size: :lg, type: "submit") %>

<%= render Deckplate::Data::TableComponent.new(rows: @readings, caption: "Sensor readings", sort: params[:sort], dir: params[:dir], sort_url: ->(key, dir) { readings_path(sort: key, dir:) }) do |t| %>
  <% t.with_column(:name, header: "Sensor", sortable: true) { |r| r.name } %>
  <% t.with_column(:value, header: "Value", align: :end, numeric: true) { |r| number_with_precision(r.value, precision: 2) } %>
<% end %>

<%= render Deckplate::Data::GaugeComponent.new(value: 72, label: "Power", color: :info) %>
```

---

## 9. Stimulus controllers and behaviours

Idempotent `connect`/`disconnect` (Turbo cache + morph safe), no global state, no timers left running after
disconnect, no inline handlers.

| Identifier | Purpose |
|---|---|
| `dp-tabs` | roving tabindex, arrow/Home/End keys, `aria-selected`, optional URL hash sync |
| `dp-menu` | popover open/close, arrow-key navigation, Esc, focus return |
| `dp-modal` | `showModal()`/`close()`, backdrop click, Esc, scroll lock, focus return; closes on `turbo:submit-end` success |
| `dp-toast` | auto-dismiss with pause on hover/focus; removes element; respects `data-dp-duration` |
| `dp-slider` | live value readout |
| `dp-clock` | 1 Hz update from server-provided epoch offset; pauses when tab hidden |
| `dp-theme` | theme switcher; sets `data-dp-theme` and `dp_theme` cookie |
| `dp-sound` | opt-in synthesised beeps (WebAudio), mute toggle persisted; never autoplays; no files |
| ~~`dp-sidebar`~~ | dropped (ADR 0006): the frame sidebar collapses with a native popover and CSS only |
| `dp-values` | CSP-safe application of per-instance CSS values (section 11) |

Registration (ADR 0004): primary `import { registerDeckplate } from "deckplate"; registerDeckplate(application, { only, except })`;
also supported: `eagerLoadControllersFrom("deckplate/controllers", application)`.

---

## 10. Accessibility requirements (acceptance criteria, not suggestions)

- Native elements first; ARIA only per WAI-ARIA Authoring Practices for the pattern (tabs, menu button,
  dialog, switch, disclosure, meter, progressbar).
- Contrast: every documented text/background pair in every theme ≥ 4.5:1 (≥ 3:1 for large text and UI
  boundaries). Enforced by an automated spec that parses the theme variables (no manual claims).
- Visible focus ring (`--dp-focus`, ≥ 3:1, 2 px+ offset) on every interactive element.
- Keyboard: every interactive component fully operable; no focus traps except modal dialogs; Esc closes
  overlays; focus returns to the trigger.
- Colour never the sole signal (text/icon/shape accompany status).
- `prefers-reduced-motion: reduce` → all animations and transitions reduced to near-instant; pulsing
  and cascades off. `prefers-contrast: more` → thicker borders and no translucency (best effort).
  `forced-colors: active` → components remain usable (borders via `CanvasText`/`ButtonText`).
- Targets ≥ 44×44 px for primary controls on coarse pointers (`@media (pointer: coarse)`).
- Zoom to 200 % and text-only zoom without loss of content/function; responsive collapse of the frame.
- Decorative shapes (`Elbow`, `Bar`, `Cap`, `DataCascade`) are `aria-hidden="true"` unless they carry a label.
- Sound is opt-in and always has a visible mute control; no information is conveyed only by sound.
- All strings translatable; `lang` respected.

---

## 11. Content Security Policy

Per-instance dynamic values (gauge percentage, bar heights, elbow custom sizes) default to inline `style`
attributes setting custom properties (`style="--dp-value: 72"`). Strict CSPs without `'unsafe-inline'` for
styles block this. Therefore:
- `config.csp_safe_values = true` switches components to emit `data-dp-value="72"` plus quantised classes
  `dp-v-0 … dp-v-100` (1 % steps, generated in CSS) which need no JS and no inline style;
  `dp-values` Stimulus controller handles arbitrary values via CSSOM (`style.setProperty`, allowed by CSP).
- No inline `<script>`; no `eval`; fonts and CSS served same-origin.
- A spec renders every preview with `csp_safe_values = true` and asserts the HTML contains no `style=`
  attribute.

---

## 12. Quality gates and budgets

| Gate | Threshold |
|---|---|
| Line coverage (SimpleCov) | ≥ 95 % |
| RuboCop (omakase) | 0 offences |
| axe (WCAG 2.2 AA tags) | 0 violations on every preview × every theme |
| Contrast spec | all pairs pass |
| Visual regression | no diff beyond threshold across previews × 5 themes × 3 widths (375, 768, 1280) |
| CSS size (`deckplate.css`) | ≤ 80 KB raw / ≤ 12 KB gzip (raw raised from 60 KB by ADR 0009) |
| JS size (all controllers) | ≤ 20 KB raw / ≤ 6 KB gzip, no runtime dependencies |
| Fonts | ≤ 90 KB total woff2 |
| Install | `bin/integration` passes on (a) Rails + Propshaft + importmap, (b) the same + Tailwind 4 |
| Gem | `gem build` succeeds; installed from the built gem into a fresh app and renders the gallery page |

Budgets are asserted by specs; if a budget must be raised, record an ADR.

---

## 13. Documentation deliverables

- `README.md`: what/why, screenshot, 5-minute quickstart, compatibility, disclaimer.
- Lookbook: one preview file per component with `default`, each variant, edge cases (long text, empty,
  error), and a toolbar to switch theme. This is the living component documentation.
- `docs/guides/`: installation, theming (authoring a theme), Turbo patterns (frames, streams, toasts,
  morphing), accessibility, forms, CSP, Tailwind coexistence, upgrading.
- `CHANGELOG.md` (Keep a Changelog), semantic versioning.
- `CREDITS.md`: fonts (OFL), studied-but-not-copied references, contributors.
