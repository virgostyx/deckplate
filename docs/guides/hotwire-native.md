# Hotwire Native

Hotwire Native (iOS, Android) shows your Rails pages in a web view inside a native app. Deckplate adapts where it can and leaves the rest to the app (ADR 0019).
It was checked with a native user agent and emulated touch in Chrome, not on a device.

## Detection
The native clients add "Hotwire Native iOS; Turbo Native iOS;" (or "...Android...") to the user agent. In a view:

```erb
<% if dp_native? %> ... <% end %>
```

`dp_native?` needs no turbo-rails (it tests for "Hotwire Native" or "Turbo Native", the name before the rename). With the installer's layout, `<html>` also gets
`data-dp-native="true"` for a native client (through `dp_theme_attrs`), and the stylesheet uses it.

## What Deckplate does
- **Touch targets** are 48 px in a native client (`--dp-touch-min: 3rem`; 44 px elsewhere on touch screens).
- **No tap highlight**, and no double-tap delay on links, buttons and fields.
- **Hover styles only where there is a hover** (`@media (hover: hover)`), on every page: a tap never leaves a sticky hover state.
- **Safe areas**: fixed toasts and the Frame drawer stay clear of the notch and the home indicator. This takes effect only if your page asks for it:
  `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`; without `viewport-fit=cover` the insets are zero.
- The Frame drawer (narrow screens) opens from the side where the layout starts, also in right-to-left text.

## What the app decides
- **Navigation chrome**: the native app already has a navigation bar and back button. Use `Frame.new(variant: :minimal)`, or no Frame, in a native client
  (`variant: (dp_native? ? :minimal : :classic)`), and keep page-level headings with `PageHeader`.
- **Native features** (bridge components, path configuration, native screens) are outside Deckplate.
- **Minimum OS**: `Menu`, `Tooltip` and the Frame drawer use the native popover attribute, and `Modal` uses `<dialog>`; check that your minimum iOS or Android
  web view supports them. A `Tooltip` is never essential (hover is not available on touch).
- **Cookies and theme**: the theme switcher stores a cookie; check that your app's web view keeps cookies between launches if you want the theme to persist.
- **Sound** (`config.sounds`) follows the web rules: nothing plays before a user gesture.
