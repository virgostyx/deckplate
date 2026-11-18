# ADR 0018 — Two more themes, and sound packs per theme

Status: accepted (Phase 9)

## Context
SPEC 5.5 ships five themes (classic, azure, nocturne, daylight, crimson). The backlog asks for more themes and per-theme sound packs.
Contrast, axe, visual and token-export checks already run for every theme, so a theme is cheap to add and to verify.

## Decisions
1. **verdant**: dark, phosphor-terminal greens on a green-tinted near-black. **high-contrast**: pure black canvas, white text, bright roles; every text
   pair meets WCAG AAA (7:1), every boundary 4.5:1 (checked by a spec that only this theme must pass). One documented exception: the text on the
   pure-red `emergency` fill is 5.25:1 (AA); a red light enough for 7:1 would be taken for `danger`. Names are neutral colour/quality words.
2. Four palette stops are added for them (`mint`, `teal`, `lime`, `coral`), each with the ink that reads best on it (the palette spec already checks that).
3. An optional token `--dp-track` (fallback `--dp-line`) colours the unfilled part of gauges and sliders, so that `high-contrast` can keep white borders and still give
   its meter fills 3:1 against a darker track. Roles that cannot reach 3:1 on a track dark enough to stand out from the canvas (muted, the pure-red emergency) are exempt.
4. The list of built-in themes has one source, `Deckplate::Configuration::BUILT_IN_THEMES`; the token export, the visual tool, the Lookbook toolbar and the
   specs read it instead of repeating it. The order is the order of the theme switcher.
5. **Sound packs**: `dp-sound` plays a set of four tones (tick, confirm, alert, error) chosen by the active `data-dp-theme`, read at play time (so the
   theme switcher changes the sound at once). A theme without a pack of its own (a custom theme from `rails g deckplate:theme`) uses the classic pack.
   All tones stay synthesised with WebAudio; none imitates a known sound.
6. Visual baselines for the two themes are added to the existing matrix (3 widths); Q-007's threshold (80 MB) is watched: about 61 MB after this change.

## Consequences
- `ships the five themes of SPEC 5.5` becomes "ships the built-in themes"; SPEC 5.5 lists seven.
- The palette has 43 stops.
- A theme remains a set of CSS variables: no component changes.
