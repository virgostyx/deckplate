# ADR 0002 — Elbow technique

Status: accepted for Chrome and Firefox; **WebKit verification pending** (see Q-004)

## Context
SPEC §6.4 lists (A) `mask-image` with gradients (truly transparent inner arc) and (B) a canvas-coloured pseudo-element.
Spike: one element, 6u × 9u (u = 1.375rem), arms col 2.5u / bar 1.25u, outer radius 3u, inner radius 1.5u, placed at a
fractional offset (10.37px, 7.61px), screenshotted at device pixel ratios 1, 1.25, 1.5, 1.75, 2 (browser zoom 100–200 %
is the same thing for rendering) in Chrome (system channel) and Firefox 159, via Playwright 1.65.1.
Metrics per pixel, using the analytic shape with a 1.5 css px margin around every boundary:
**seam** = pixel clearly inside the shape that is not exactly the fill colour, or clearly outside that is not exactly the
background; **leak** = pixels of the cut-out that differ from a patterned page background (transparency check).
The harness lives in `tmp/spikes/pw/elbow.{html,mjs}` (not committed; the technique is documented here).

## Results
| Technique | Chrome seams | Firefox seams | Transparent over a pattern |
|---|---|---|---|
| A  naive: two arm layers + radial-gradient fillet tile at (col, bar) | 0 at DPR 1/2, **28–40 px at 1.25/1.5/1.75** | 0 | yes (0 leak) |
| **A2 = A with the fillet tile enlarged by 1px onto the arms** | **0 everywhere** | **0 everywhere** | **yes** |
| B  canvas-coloured `::after` | up to 428 px at 1.25/1.75 | 0 | **no, 100 % leak** |

Reference comparison (`LCARS-24.2/classic-standard.html` at 1280×800, studied only): elbow column ≈ 180px, bar ≈ 20px,
outer radius ≈ 90px, inner radius ≈ 40px, gap between stacked pieces ≈ 8px. At u = 22px that is col ≈ 8u, bar ≈ 0.9u,
r ≈ 4u, ri ≈ 1.8u, gap ≈ 0.4u: the SPEC §5.4 starting values (col 6u, bar 1.25u, r 3u, ri 1.5u) are a little small/thick;
retune in Phase 2 task 7.

## Decision
Technique **A2**. Outer arc: `border-radius` on one corner. Shape = union of three mask layers:
```css
mask:
  linear-gradient(#000 0 0) 0 0 / 100% var(--dp-elbow-bar) no-repeat,                 /* horizontal arm */
  linear-gradient(#000 0 0) 0 0 / var(--dp-elbow-col) 100% no-repeat,                 /* vertical arm */
  radial-gradient(circle at 100% 100%, transparent calc(var(--dp-elbow-ri) - .5px),
                  #000 calc(var(--dp-elbow-ri) + .5px))
    calc(var(--dp-elbow-col) - 1px) calc(var(--dp-elbow-bar) - 1px)
    / calc(var(--dp-elbow-ri) + 1px) calc(var(--dp-elbow-ri) + 1px) no-repeat;       /* inner fillet, overlaps arms by 1px */
```
The 1px overlap is mandatory (it removes the hairline where two mask layers abut at fractional device pixels).
Other corners mirror the layer positions. Backgrounds: no canvas-colour dependency.

## Consequences
- Elbows work over any background, gradient or theme.
- Phase 2 must add a regression spec (Playwright, DPR 1.25/1.5/1.75, patterned background) reproducing the seam and leak
  metrics above for all four corners.
- If WebKit shows seams, fall back to widening the overlap (2px) before reconsidering B.
- Safari >= 15.4 and current Chrome/Firefox support unprefixed `mask` shorthand; no `-webkit-` prefix planned.
