# Changelog

All notable changes are documented here. Format: [Keep a Changelog](https://keepachangelog.com/), semantic versioning.

## [Unreleased]

### Added
- Project skeleton (Phase 0) and ADRs 0001-0005.
- Phase 1 foundations: generated colour tokens (palette stops, roles), five themes (`classic`, `azure`, `nocturne`,
  `daylight`, `crimson`), bundled OFL fonts, `.dp-root` base styles, `Deckplate.configure`, `BaseComponent` with
  colour/size/variant concerns, view helpers (`dp_root`, `dp_theme_attrs`, `dp_color_class`, `dp_icon`, `dp_font_tags`),
  English and French locale skeletons.
- Phase 2 shapes and layout: `Spacer`, `Cap`, `Divider`, `Bar` (segments, caps, vertical), `Elbow` (four corners, transparent
  inner arc, labels), `Block`, `Bracket`, `Panel` (plain bars or elbow corners), `PageHeader`, `Section`, `Frame`
  (classic / double / minimal, container-query collapse, native-popover sidebar, `fixed` mode, skip link).
- `bin/visual --geometry`: elbow seam, edge-straightness and transparency check in Chrome, Firefox and WebKit.

### Changed
- Geometry tokens retuned against a reference console: bar 0.9u, gap 0.35u, column 8u, outer radius 4.5u, inner radius 1.8u.
- `.dp-root` resets its margin.
