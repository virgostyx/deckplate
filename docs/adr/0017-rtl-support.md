# ADR 0017 — Right-to-left support

Status: accepted (Phase 9)

## Context
Most of Deckplate already uses logical CSS properties (`inline-start`, `padding-inline`, grid order), so text, forms, buttons, navigation and the Frame
grid mirror under `dir="rtl"`. A side-by-side comparison of every preview (LTR flipped vs RTL, 768 px, classic) found what does not:
1. **Elbow**: four physical corners (`top_left`...) drawn with physical radii and mask positions. The shape keeps its left/right geometry
   while the layout around it flips; Panel and Frame place corners by logical position but draw them with physical names: garbled in RTL.
2. **Directional icons** (chevrons) point the same way in both directions.
3. **Slider** fill is a `to right` gradient.
4. **Tooltip / Menu** JavaScript computes physical coordinates and writes them to `inset-inline-start`.
5. **Readout / Clock**: a value and its unit are reordered by the bidi algorithm ("18.4 °C" shows as "°C 18.4").

## Decisions
1. The direction comes from the host (`dir="rtl"` on `<html>` or any container). Deckplate never sets it. No locale is added for it.
2. **Logical corner names for Elbow**: `top_start`, `top_end`, `bottom_start`, `bottom_end` mirror with the direction (CSS `:dir(ltr|rtl)`; supported by
   Chrome 120+, Firefox 49+, Safari 16.4+). The physical names stay and never mirror (for a shape that must stay on one side). Panel and Frame use the
   logical names. Frame slots become `top_start_corner` / `bottom_start_corner`; the old `*_left_corner` names remain as aliases.
3. Directional icons (`chevron_left`, `chevron_right`) get the class `dp-icon--directional`, flipped horizontally in RTL.
4. Fill gradients use `to right` in LTR and `to left` in RTL.
5. Popover JS positions with physical `left` (it computes physical coordinates), not `inset-inline-start`.
6. Values that are data (the Readout number and unit, each, and the Clock) are isolated as LTR (`direction: ltr; unicode-bidi: isolate`), also in an RTL page.
   The flex row of a Readout still follows the page direction.
7. Verification: computed-style specs per corner and direction; a pixel mirror check (a text-free preview rendered in RTL must equal the LTR render
   flipped); visual baselines for RTL (classic, 768 px).

## Consequences
- Physical corner names remain valid, so existing code is unchanged; the docs recommend the logical ones.
- Vertical bars (top/bottom caps) do not mirror. The Frame entrance animation (`animate: true`) reveals and slides from the start side in both directions with the layout.
- Out of scope: translations (`ar`, `he`), bidi text inside user content, mirrored Sparkline/BarGraph data order (data order is the data's).
