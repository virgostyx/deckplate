# ADR 0008 — Form controls: where options go, errors, focus, and Turbo morph

Status: accepted (Phase 4)

## Context
Forms are the part of a UI library where accessibility and Turbo behaviour matter most. Four questions came up while building the
controls and the `FormBuilder`, each answered by a failing system spec first.

## Decisions
1. **`**html_options` go to the native control**, not to the wrapper (class, data, aria, placeholder, min/max, autocomplete...).
   This departs from other components, where they go to the root element, because the control is what integrators customise.
   `aria-describedby` is *added to* the caller's value (BaseComponent merges that token list like `data-controller`).
2. **Errors and hints are wired by id**: every control renders inside `FormField`, which owns the label, the hint (`<id>-hint`) and
   the errors (`<id>-error`); the control points at them with `aria-describedby` and gets `aria-invalid`. Errors always have an icon
   and a text prefix. When a control draws its own label (checkbox) the hint moves after the control.
3. **Only the first invalid field of a form is an alert and is focused.** The builder shares that state with nested builders
   (`fields_for`). It sets `autofocus` *and* `data-controller="dp-autofocus"`: Turbo honours `autofocus` on a normal render but
   **not when it morphs the page** (measured: focus stayed on `<body>` with `turbo-refresh-method=morph`), and Stimulus does connect
   elements added by a morph.
4. **A touched field keeps its value across a morph refresh** (`dp-field`, on every `FormField`). Measured: a morph reset typed text,
   selected options and ticked boxes of fields the user was not editing at that moment. After the first `input`/`change`, the field
   cancels the morph of `value`/`checked`/`selected` (`turbo:before-morph-attribute`). Untouched fields still follow the server.

## Consequences
- A server that must overwrite a field the user has edited has to replace the element (change its `id`) or use a Turbo Stream.
- `required` is detected from unconditional `presence` validators; pass `required:` to override.
- `select multiple`, grouped checkboxes and inline (client-side) validation are not part of v1.0 (PLAN backlog).
- The date control has four tab stops in Chrome (month, day, year, calendar button): the keyboard system spec accounts for it.
