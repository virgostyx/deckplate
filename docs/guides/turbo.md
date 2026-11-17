# Turbo patterns

Set `turbo_refreshes_with method: :morph` (or the meta tag) if you want page refreshes to morph; Deckplate supports it.

- **Stateful controllers protect their state.** A morph must not undo what the user just did. `dp-field` keeps touched fields, `dp-values` the
  applied CSS values, `dp-theme` the pressed theme button, `dp-sound` the mute switch (each through `turbo:before-morph-attribute`).
- **Toasts** are Turbo Stream `append`s to `#dp-toasts` (`dp_toast_container`). See `feedback.md`, including `permanent: true` and flash messages.
- **Value flicker**: `Readout.new(flicker: true)` blinks once when a Turbo Stream replaces it, never on a first load or a plain visit.
- **Forms**: invalid submissions answer 422 and re-render; the first invalid field gets focus and the error is announced (`forms.md`).
- **Theme**: the theme switcher writes a cookie; the server reads it in `dp_theme_attrs`, so a reload or a Turbo visit keeps the theme with no flash.
- **Frames**: components are render-pure (no database, no `current_user`), so they work inside `turbo_frame_tag` like any markup.
