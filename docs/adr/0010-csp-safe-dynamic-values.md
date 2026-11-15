# ADR 0010 — CSP-safe dynamic values

Status: accepted (Phase 5)

## Context
Components with dynamic numbers (a gauge percentage, a bar thickness, an elbow size, a spacer) need per-instance CSS values. Writing them
as `style="--dp-n: 2"` is blocked by a strict `style-src` (no `'unsafe-inline'`). SPEC section 11 sketched quantised classes
(`dp-v-0..100`) plus a `dp-values` controller; only percentages fit classes, the rest are arbitrary numbers or `calc()` strings.

## Decision
One entry point in `BaseComponent#html_attributes`, used by every component with dynamic values:
- `percent: 72.4` -> default: `style="--dp-value: 72.4"`; with `csp_safe_values`: class `dp-v-72` (generated for 0..100 by `bin/build-css`)
  and `data-dp-value="72"`. No JavaScript, no style attribute.
- `vars: { "--dp-n": 2 }` -> default: inline style; with `csp_safe_values`: `data-controller="dp-values"` and
  `data-dp-values-vars-value='{"--dp-n":"2"}'`, applied by the controller with `style.setProperty` (the CSSOM is allowed by CSP).
- `dynamic_attributes(...)` gives the same for child elements (bars of a graph).
The controller also wires `turbo:before-morph-attribute` so that the `style` attribute it wrote is not removed by a morph (the server
markup has none): found by a failing system spec, the first version forgot the `data-action`.

## Verification
- `spec/csp_previews_spec.rb`: every preview in CSP mode has no `style` attribute on a Deckplate element and no inline `<script>`/`<style>`
  in the body.
- `spec/system/data_spec.rb`: a page served with `style-src 'self'` (no `unsafe-inline`) records `securitypolicyviolation` events
  (none) and the computed sizes are right (spacer, elbow, bar, segment, gauge, progress, graph), also after a morph refresh.

## Consequences
- Quantised classes cost about 3 KB raw / 0.6 KB gzip of CSS for every host, CSP mode or not.
- Percentages are rounded to whole numbers in CSP mode (1 % steps); the default mode keeps decimals.
- Integration note, not a Deckplate matter: Turbo injects a `<style>` for its progress bar and applies the `csp-nonce` meta to it, so a host
  with a strict policy must include `style-src` in `content_security_policy_nonce_directives` (or style the bar itself).
