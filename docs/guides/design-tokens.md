# Design tokens export

`config/deckplate/tokens.json` (shipped in the gem) lists Deckplate's colours and font stacks in the W3C design tokens format, for Style Dictionary 4,
Tokens Studio, or a Figma variables import. It is generated from the same files as the CSS (`palette.yml`, the theme stylesheets, `foundation.css`) by
`bin/build-css`; a spec fails when it is stale and checks that every theme resolves to the colours the CSS resolves to.

```
dp.palette.<stop>          colour stops and their ink (text on the stop): neon-carrot, neon-carrot-ink, ...
dp.font.display|data|text  font stacks (type fontFamily)
dp.theme.<theme>.<token>   classic, azure, nocturne, daylight, crimson: primary ... emergency, ink variants, canvas, surface, ink, line, focus, ...
```

Theme tokens are aliases to the palette (`{dp.palette.neon-carrot}`) where the CSS uses a palette variable, and literal colours otherwise.
A stop marked `$extensions.dp.backgroundOnly` must not be used as text or line colour on the canvas.

Style Dictionary example:

```js
export default { source: ["path/to/deckplate/config/deckplate/tokens.json"],
  platforms: { css: { transformGroup: "css", buildPath: "build/", files: [{ destination: "vars.css", format: "css/variables" }] } } }
```

Not exported: geometry (sizes, radii, elbow proportions) and motion. They are `calc()` and `var()` chains that only make sense inside the cascade.
Custom themes created with `rails g deckplate:theme` are not part of this file.
