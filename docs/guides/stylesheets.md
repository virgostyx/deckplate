# Stylesheets

One line is enough:

```erb
<%= stylesheet_link_tag "deckplate" %>   <%# everything: core + the four families (about 12 KB gzipped) %>
```

If you use only a few families, link the core and the families you need. The sheets can be in any order (each one starts with the layer
prelude, see the Tailwind guide):

```erb
<%= stylesheet_link_tag "deckplate-core" %>       <%# tokens, themes, fonts, base, shapes, layout, icon: always needed %>
<%= stylesheet_link_tag "deckplate-controls" %>   <%# Button, Nav, Tabs, Menu, Modal, ... %>
<%= stylesheet_link_tag "deckplate-forms" %>      <%# FormField, inputs, checkbox/radio, FormActions %>
<%= stylesheet_link_tag "deckplate-data" %>       <%# Readout, Table, Gauge, Progress, BarGraph, ... %>
<%= stylesheet_link_tag "deckplate-feedback" %>   <%# Alert, Toast, ConditionBanner, Spinner, ... %>
```

| Sheet | Raw | Gzip |
|---|---|---|
| `deckplate-core.css` | 37 KB | 6.5 KB |
| `deckplate-controls.css` | 17 KB | 3.1 KB |
| `deckplate-forms.css` | 5 KB | 1.4 KB |
| `deckplate-data.css` | 11 KB | 2.3 KB |
| `deckplate-feedback.css` | 7 KB | 1.6 KB |
| `deckplate.css` (all of the above) | 76 KB | 11.9 KB |

## Dependencies between families

The families do not depend on each other for their own components, but some components contain others:

* a `Menu` renders a `Button` (controls: same family);
* an `EmptyState`, an `Alert` or a form often hold a `Button` (link `deckplate-controls`);
* the form builder's submit is a `Button`; its `FormActions` row is in `forms`.

When in doubt, use `deckplate.css`.

## Measuring

`bin/budgets` prints the size of every sheet against its limit (SPEC section 12, ADR 0012).
