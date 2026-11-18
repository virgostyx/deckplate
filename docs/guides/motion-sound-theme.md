# Motion, sound and theme switching

## Motion
- `Frame.new(animate: true)`: header reveal, then sidebar and main fade in (300/400/500 ms, staggered). Off by default.
- `Readout.new(flicker: true)`: a 700 ms outline blink when the readout is replaced by a Turbo Stream. Not on first load or plain visits.
- `prefers-reduced-motion: reduce` removes every animation and transition, delays included (`base.css`).

## Sound (opt-in)
```ruby
Deckplate.configure { |c| c.sounds = true }
```
- Layout: `<body class="dp-root" <%= tag.attributes(dp_sound_attrs) %>>` (or `dp_root`, which adds it). Add `SoundToggleComponent` somewhere visible.
- Tones are synthesised with WebAudio (no files): `tick` (button click), `confirm` (info/success toast), `alert` (warning), `error` (danger).
- **Each theme has its own pack of these four tones** (quieter and lower for `nocturne`, soft blips for `verdant`, longer and louder for `high-contrast`, urgent for `crimson`...).
  The pack is chosen when a tone plays, so the theme switcher changes the sound at once. A custom theme without a pack uses the classic one. Volumes are capped (gain 0.15).
- Nothing plays before the first user gesture (no AudioContext is created). The mute choice is kept in `localStorage` (`dp-sound-enabled`).
- Any code can request a tone: `window.dispatchEvent(new CustomEvent("dp:sound", { detail: { tone: "confirm" } }))`. Unknown names are ignored.
- Sound never carries information alone: every toast and alert also has text and an icon.

## Theme switcher
`ThemeSwitcherComponent` renders one `aria-pressed` button per enabled theme. `dp-theme` sets `data-dp-theme` on `<html>` and writes the
`dp_theme` cookie, which `dp_theme_attrs` reads server-side (only enabled theme names are accepted).
