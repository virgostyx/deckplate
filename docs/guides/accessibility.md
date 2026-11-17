# Accessibility

What is checked automatically, and what is not.

## Checked by the test suite
- **axe-core** on every preview in every theme (no violations).
- **Contrast** (WCAG 2.2 AA) for every colour pair of every theme (`spec/contrast`), generated from the palette.
- **Keyboard**: real key events for tabs, menu, modal, tooltip, slider, theme switcher; visible focus ring (`--dp-focus`).
- **Reduced motion**: `prefers-reduced-motion: reduce` removes animations and transitions, delays included.
- **Zoom and reflow**: every preview has no horizontal overflow at 375 px, at 640 px with a doubled root font (200 % zoom) and at 320 px (400 %).
- **Forced colours** (Windows high contrast, emulated in Chromium): buttons, alerts, toasts, fields and banners keep a border; a switch shows its
  state by position and a tick, not by colour.
- **Touch**: with a coarse pointer every control is at least 44 px tall (`--dp-touch-min`).
- **Non-colour cues**: alerts, toasts and banners carry an icon and a visually hidden kind ("Warning:"); validation errors use text and `role="alert"`;
  sound is never the only signal.
- **Layout stability**: fallback fonts are metric-matched; layout shift stays under 0.02 even when the fonts arrive late (ADR 0015).

## Not checked
- **No test with a real screen reader yet** (a manual checklist is in `screen-reader-checklist.md`) (NVDA, JAWS, VoiceOver, TalkBack). ARIA roles and names are verified by axe and by specs, which does not prove
  how a screen reader announces them. Run one before relying on a component in a critical flow.
- Forced colours is emulated in Chromium only; Firefox and Windows themselves were not tested.
- Automatic checks cover only part of WCAG; focus order in a host page, copy and language are the host's responsibility.

## Known limitations
- `classic`: `primary` (#FF9933) and `warning` (#FF9900) are almost the same orange. Components never rely on colour alone (see above), but do not
  use the two side by side to mean different things. See Q-009.
- A large `Elbow` (md and up) is a fixed-size decorative shape: alone on a screen narrower than its width (320 px at the default size) it overflows.
  Inside `Panel` and `Frame` it is laid out by the container. `Bar` segments with `size:` shrink on narrow screens.
- Decorative shapes (Elbow, Bar, Cap...) are `aria-hidden`; give meaningful content real text.
