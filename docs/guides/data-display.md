# Data display

All data components live in `Deckplate::Data::` and take plain values: no models, no database.

| Component | Use |
|---|---|
| `ReadoutComponent` | A labelled value in tabular monospace. `trend: :up/:down/:flat` adds an icon and a text alternative |
| `DataListComponent` | Key/value panel (`<dl>`), from pairs or slots |
| `StatusPillComponent` | `:ok :warn :fail :idle :info`: text, icon and colour (never colour alone) |
| `ProgressComponent` | `role="progressbar"`; `value: nil` is indeterminate; `segments: 10` for a segmented bar |
| `GaugeComponent` | `role="meter"`, pure CSS, `variant: :radial` or `:semicircle` |
| `BarGraphComponent` | Server-rendered bars; the data is repeated in a visually hidden table |
| `SparklineComponent` | Inline SVG polyline computed on the server; the label summarises min, max, first, last |
| `TableComponent` | Real table with sortable headers, footer, empty state |
| `ClockComponent` | `dp-clock`: ticks from the server's time, pauses in a hidden tab |
| `DataCascadeComponent` | Decorative, seeded (same HTML for the same inputs), `aria-hidden` |

## Table and the sorting contract

```erb
<%= render(Deckplate::Data::TableComponent.new(
      rows: @readings, caption: "Sensor readings",
      sort: params[:sort], dir: params[:dir],
      sort_url: ->(key, dir) { readings_path(sort: key, dir: dir) })) do |t|
  t.with_column(:name,  header: "Sensor", sortable: true, row_header: true) { |r| r.name }
  t.with_column(:value, header: "Value",  sortable: true, align: :end, numeric: true) { |r| number_with_precision(r.value, precision: 2) }
  t.with_footer { tag.tr { tag.th("Total", scope: "row") + tag.td(@total, class: "dp-table__cell--end") } }
  t.with_empty { "Nothing recorded yet." }
end %>
```

* **The host sorts.** Pass the current `sort`/`dir` and a `sort_url` lambda; the component renders sortable headers as links, marks the
  sorted column with `aria-sort`, and flips the direction in the next link. There is no client-side sorting.
* `sort` and `dir` come from the URL, so they are *untrusted*: anything that is not a sortable column key or `asc`/`desc` is ignored.
  Sort in the host with an allowlist of columns, never `order(params[:sort])`.
* `caption:` is mandatory (it names the table); `caption_hidden: true` keeps it for screen readers only.
* The wrapper is a named, keyboard-focusable `role="region"` so that wide tables can be scrolled without a mouse.
* A cell block may return a String, a number, a date or nil, or write markup (`render ...`).
* `row_id: ->(row) { "reading_#{row.id}" }` puts an id on each row for Turbo Streams.

## Live updates with Turbo Streams

Give the component a stable DOM `id:` and replace it:

```ruby
render turbo_stream: [
  turbo_stream.replace("power-gauge", Deckplate::Data::GaugeComponent.new(label: "Power", value: 77, id: "power-gauge")),
  turbo_stream.replace("temp-readout", Deckplate::Data::ReadoutComponent.new(label: "Coolant", value: 19.7, unit: "°C", id: "temp-readout"))
]
```

`turbo_stream.replace` accepts a component directly. The element is replaced as a whole (its CSS value comes with it), assistive technology
keeps its place, and no JavaScript of ours is involved. See the demo in `spec/dummy/app/controllers/dashboards_controller.rb`.

## Timeline

```erb
<%= render(Deckplate::Data::TimelineComponent.new(aria: { label: "Mission log" })) do |t|
  t.with_event(title: "Launch", time: "14:02", datetime: "2026-11-17T14:02", state: :done) { "Left the dock." }
  t.with_event(title: "Transit", time: "16:10", state: :current)
  t.with_event(title: "Arrival", state: :upcoming)
end %>
```

States are `:done` (default; a check in a filled marker), `:current` (a ring with a dot, `aria-current="step"`) and `:upcoming` (a dashed empty marker).
The state is never carried by colour alone: the marker has a shape and a visually hidden text ("Completed", "Current", "Upcoming"; `en` and `fr`) follows the
title. `time:` takes a text or a `Time` (shown as `YYYY-MM-DD HH:MM`, with its ISO 8601 value in the `datetime` attribute); `datetime:` goes with a text. An event can
take its own colour role (`color: :danger`). To update a timeline with a Turbo Stream, give it a stable `id` and `turbo_stream.replace` it (see the dashboard in the dummy app).

## Content-Security-Policy

Set `config.csp_safe_values = true` (in `config/initializers/deckplate.rb`) when your `style-src` forbids `'unsafe-inline'`:

* percentages become classes (`dp-v-72`), arbitrary values travel in `data-dp-values-vars-value` and are applied with the CSSOM;
* no component writes a `style` attribute or an inline script (checked over every preview, and in a browser under a strict policy);
* Keep `<%= csp_meta_tag %>` in your layout: Turbo reads the nonce from it, and without it a per-request nonce on the tracked importmap tag
  makes every Turbo visit a full page load (measured in the dummy app).
* Turbo's own progress-bar `<style>` needs the nonce: add `style-src` to `config.content_security_policy_nonce_directives`
  (or style `.turbo-progress-bar` yourself). See ADR 0010.

## Accessibility notes

* Gauge, progress and graph expose their values through ARIA (`meter`, `progressbar`) or a hidden table; the visual part is decorative.
* A trend or status is always an icon plus text. A missing readout value shows a dash with the text "No value".
* The clock is `role="timer"`: it is not a live region, so nothing is announced every second.
