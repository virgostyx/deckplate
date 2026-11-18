# ADR 0019 — Hotwire Native: what Deckplate does, and what it leaves to the app

Status: accepted (Phase 9)

## Context
Hotwire Native (iOS and Android) shows Rails pages in a web view, with native navigation around them. Its clients add "Hotwire Native iOS; Turbo Native iOS;"
(or the Android equivalent) to the user agent; turbo-rails' `hotwire_native_app?` tests for "Hotwire Native" (`turbo_native_app?`, for "Turbo Native", is the
older name). Sources: native.hotwired.dev (iOS and Android configuration), turbo-rails pull request 691.

## Decisions
1. **Detection without a dependency**: `dp_native?` matches `/(Hotwire|Turbo) Native/i` on the user agent, so Deckplate does not require turbo-rails.
2. `dp_theme_attrs` adds `data-dp-native="true"` to `<html>` for a native client, so existing layouts need no change.
3. In a native client (`[data-dp-native]`): touch targets 48 px (`--dp-touch-min: 3rem`, the Android minimum; the default 2.75rem is 44 px), no tap highlight,
   `touch-action: manipulation` on controls (no double-tap delay).
4. Everywhere, because it matters on every touch screen and the native web view is one: **hover styles apply only under `@media (hover: hover)`**, so a tap does
   not leave a sticky hover; fixed toasts and the Frame drawer keep clear of the device insets with `env(safe-area-inset-*)` (zero unless the page uses `viewport-fit=cover`).
5. Found on the way: the Frame drawer opened from the physical left in RTL. It now opens from the side where the layout starts (logical `inset-inline`).
6. Not done on purpose: no native bridge components, no path configuration, no hiding of web chrome (the app decides: a `Frame` of variant `minimal`, or none, with
   `dp_native?` in the view). Nothing was tested on a device: the checks use a native user agent and emulated touch in Chrome.

## Consequences
- Specs: detection (`spec/helpers/deckplate/native_spec.rb`), a static check that every `:hover` rule is guarded and that the native and safe-area rules exist
  (`spec/native_css_spec.rb`), a browser check with a native user agent, and the RTL drawer.
- The guide `docs/guides/hotwire-native.md` lists what a native app should decide for itself.
