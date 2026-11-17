# Content Security Policy

Deckplate works with a strict policy (no `'unsafe-inline'` for scripts or styles):
- no inline `<script>`, no `eval`; the JavaScript comes from your importmap (use Rails' nonce support for the importmap tags);
- fonts and CSS are served from your own origin by Propshaft;
- per-instance values (a gauge at 72 %, a bar height, a custom elbow size) are written as `style="--dp-value: 72"` by default, which a strict
  `style-src` blocks. Turn on:

```ruby
Deckplate.configure { |c| c.csp_safe_values = true }
```

Components then emit quantised classes (`dp-v-0` to `dp-v-100`) and `data-dp-values-vars-value`; the `dp-values` controller applies the values with
the CSSOM (`style.setProperty`), which a policy allows. No `style=` attribute is rendered. A spec renders every preview this way and checks it.

Limit: percentages are rounded to whole numbers in this mode.
