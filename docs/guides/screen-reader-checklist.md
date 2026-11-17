# Screen reader smoke test (manual)

Run once per release candidate, with Orca on Linux (Firefox or Chromium) and, when available, NVDA/VoiceOver. Start the dummy app with `bin/dev`.
For each row, note what is announced and mark OK / issue. Record the date, browser, screen reader and version at the top of the results.

| # | Page (under `http://localhost:3000/rails/view_components/`) | What to do | Expected announcement |
|---|---|---|---|
| 1 | `frame/classic` | Browse by landmarks and headings | Banner/navigation/main regions; one `h1`; decorative bars and elbows are silent |
| 2 | `button/default` | Tab to each button; Space/Enter | "Button, <label>"; a disabled button is announced as unavailable; a loading button as busy |
| 3 | `nav/default` | Tab through, arrow keys where documented | Current page announced ("current page"); list structure read |
| 4 | `tabs/default` | Tab to the tablist, arrow keys, Home/End | "Tab, selected, n of m"; the panel is announced when it opens |
| 5 | `modal/default` | Open, Tab around, Escape | Dialog name read on open; focus trapped; focus back on the trigger when closed |
| 6 | `toast/default` (or `/toasts` in the dummy app) | Trigger a success and an error toast | Success read politely, error read at once ("alert"); kind word ("Danger:") read before the message |
| 7 | `text_input/default`, `select/default`, `checkbox/default` | Tab through; submit an invalid form | Label, required state, hint and error read with the field; first invalid field focused and its error announced |
| 8 | `toggle/default` | Space | "Switch, on/off" |
| 9 | `table/default` | Table navigation keys (Ctrl+Alt+arrows) | Column headers read for each cell; sort state of a sortable header announced |
| 10 | `gauge/default`, `progress/default` | Browse | Role (meter/progressbar), value and range read |
| 11 | `clock/default` | Browse | Timer role; the time is not re-announced every second |
| 12 | `theme_switcher/default` | Tab, Space | "Pressed/not pressed" on each theme button; group name read |
| 13 | `sound_toggle/default` (with `config.sounds = true`) | Space | "Switch, Sound, on/off"; muting stops the beeps |

## Results
_Not run yet._ (Add: date, OS, browser, screen reader + version, and a line per row.)
