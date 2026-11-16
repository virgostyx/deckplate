# Changelog

All notable changes are documented here. Format: [Keep a Changelog](https://keepachangelog.com/), semantic versioning.

## [Unreleased]

### Added
- Phase 7 (in progress): `Frame animate:` entrance cascade, `Readout flicker:`, `ThemeSwitcherComponent` (`dp-theme`, cookie), opt-in sound
  (`config.sounds`, `dp-sound`, `SoundToggleComponent`, `dp_sound_attrs`; ADR 0013; guide `docs/guides/motion-sound-theme.md`).
- Project skeleton (Phase 0) and ADRs 0001-0005.
- Phase 1 foundations: generated colour tokens (palette stops, roles), five themes (`classic`, `azure`, `nocturne`,
  `daylight`, `crimson`), bundled OFL fonts, `.dp-root` base styles, `Deckplate.configure`, `BaseComponent` with
  colour/size/variant concerns, view helpers (`dp_root`, `dp_theme_attrs`, `dp_color_class`, `dp_icon`, `dp_font_tags`),
  English and French locale skeletons.
- Phase 2 shapes and layout: `Spacer`, `Cap`, `Divider`, `Bar` (segments, caps, vertical), `Elbow` (four corners, transparent
  inner arc, labels), `Block`, `Bracket`, `Panel` (plain bars or elbow corners), `PageHeader`, `Section`, `Frame`
  (classic / double / minimal, container-query collapse, native-popover sidebar, `fixed` mode, skip link).
- Phase 3 controls and navigation: `Button`, `ButtonGroup`, `Toggle`, `Slider` (`dp-slider`), `Nav`/`NavItem`, `TopNav`,
  `Breadcrumb`, `Pagination`, `Disclosure`, `Tabs` (`dp-tabs`), `Menu` (`dp-menu`), `Tooltip` (`dp-tooltip`), `Modal` (`dp-modal`).
  Stateful controllers survive Turbo cache restores and morph refreshes (ADR 0007).
- Phase 4 forms: `FormField`, `TextInput`, `Textarea`, `Select`, `Checkbox`, `RadioGroup`, `Range`, `FileInput`, `DateInput`,
  `FormActions` and `Deckplate::FormBuilder` (`dp_*` methods, labels/hints/errors/required from the model, nested `fields_for`,
  first-error alert and focus). Typed values survive Turbo morph refreshes (ADR 0008). Guide: `docs/guides/forms.md`.
- Phase 5 data display: `Readout`, `DataList`, `StatusPill`, `Progress`, `Gauge`, `BarGraph`, `Sparkline`, `Table` (sortable, footer,
  empty state), `Clock` (`dp-clock`), `DataCascade`; CSP-safe mode for every component with dynamic values (`dp-values`, `dp-v-0..100`,
  ADR 0010); Turbo Stream dashboard demo. Guide: `docs/guides/data-display.md`.
- Phase 6 feedback: `Alert` (`dp-dismiss`), `ConditionBanner`, `Toast` (`dp-toast`, `dp_toast_container`, Turbo Stream usage, pause on
  hover/focus, stack limit), `Spinner`, `Skeleton`, `EmptyState`, `Callout`. Guide: `docs/guides/feedback.md`.
- Stylesheets by family (ADR 0012): `deckplate-core.css` plus `deckplate-{controls,forms,data,feedback}.css`, next to the all-in-one
  `deckplate.css`; budgets are now per sheet. Guide: `docs/guides/stylesheets.md`.
- Gzip CSS budget raised to 15 KB (ADR 0011), then replaced by per-sheet budgets (ADR 0012).
- The shipped `deckplate.css` no longer contains comments or blank lines (-23% gzip); the sources keep them.
- `bin/visual --geometry`: elbow seam, edge-straightness and transparency check in Chrome, Firefox and WebKit.

### Changed
- Geometry tokens retuned against a reference console: bar 0.9u, gap 0.35u, column 8u, outer radius 4.5u, inner radius 1.8u.
- `.dp-root` resets its margin.
