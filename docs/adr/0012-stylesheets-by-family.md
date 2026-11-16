# ADR 0012 — Stylesheets by family

Status: accepted (Phase 6 review, owner decision)

## Context
ADR 0011 left one option for when the single stylesheet reached its budget: split it by family. At the end of Phase 6 the bundle is
76.0 KB raw / 11.9 KB gzip, and Phase 7 still adds motion, a theme switcher and more.

## Decision
The component CSS lives in one folder per family (`components/controls|forms|data|feedback/`); shapes, layout and the icon stay in the core.
The build (`bin/build-css`) writes:

| File | Content |
|---|---|
| `deckplate-core.css` | layer prelude, tokens, `dp-v-*` classes, fonts, themes, base, shapes, layout, icon. Required by every family |
| `deckplate-controls.css` | Button, ButtonGroup, Toggle, Slider, Nav, TopNav, Breadcrumb, Pagination, Disclosure, Tabs, Menu, Tooltip, Modal |
| `deckplate-forms.css` | FormField, text/select/file inputs, checkbox/radio, FormActions |
| `deckplate-data.css` | Readout, DataList, StatusPill, Progress, Gauge, BarGraph, Sparkline, Table, Clock, DataCascade |
| `deckplate-feedback.css` | Alert, ConditionBanner, Toast, Spinner, Skeleton, EmptyState, Callout |
| `deckplate.css` | everything in one file (core, then the families): `stylesheet_link_tag "deckplate"` stays the one-line setup |

- **Every sheet starts with the layer prelude** (ADR 0003), so sheets can be linked in any order.
- Budgets are per sheet (SPEC section 12): core 50 KB raw / 9 KB gzip, each family 25 / 5, all-in-one 120 / 20. They replace the single
  80 KB / 15 KB limit of ADR 0009 and 0011.
- A family sheet contains only `@layer dp.components` rules for the blocks of its own family.

## Verification
- `spec/css_bundle_spec.rb`: the sheets partition the all-in-one bundle (nothing lost, nothing duplicated), every sheet has the prelude,
  a block is the subject of rules in one sheet only, the core holds no family block.
- `spec/system/stylesheets_spec.rb`: in a browser, core + one family styles that family, core alone does not, the order of the links does not
  matter, the all-in-one still styles everything.
- Visual regression: the previews render pixel-identically with the all-in-one file before and after the split.

## Consequences
- A component that renders another family's component needs that sheet too (for example a `Menu` or an `EmptyState` action uses a
  Button: link `controls`). `docs/guides/stylesheets.md` lists the dependencies; the all-in-one file avoids the question.
- Fewer bytes for hosts that use few families; no change for hosts that link `deckplate.css`.
- A new component goes in the folder of its family; `bin/build-css` and the specs enforce the rest.
