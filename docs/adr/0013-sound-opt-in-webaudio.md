# 0013. Sound: opt-in, synthesised, gesture-gated

## Context
SPEC section 8 wants optional beeps, never autoplay, with a visible mute control, and no audio assets (see CLAUDE.md legal rules).

## Options
1. Audio files: rejected (assets, licensing, size).
2. WebAudio oscillators created on load: browsers block or warn, and it would play without a gesture.
3. WebAudio oscillators, context created at the first `pointerdown`/`keydown`.

## Decision
Option 3, in `dp-sound` (about 1 KB gzip). Four tones (tick, confirm, alert, error). Wiring only when `config.sounds` is true: `dp_sound_attrs`
on the root, a tick on `ButtonComponent`, a tone per `ToastComponent` kind, and `SoundToggleComponent` (hidden when sounds are off).
Mute state in `localStorage`, protected from Turbo morphs by `keepState`.

## Consequences
- Requests made before any gesture are dropped, not queued.
- The controller must not name a property `context` (it shadows Stimulus' own `Controller#context`); it uses `audio`.
- Specs use a fake `AudioContext` injected with `evaluate_on_new_document`; real audio output is not verified.
