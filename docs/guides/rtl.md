# Right-to-left languages

Set the direction yourself, as you would for any page: `<html lang="ar" dir="rtl">` (or `dir="rtl"` on any container). Deckplate never sets it and adds
no locale for it. Components follow the direction (ADR 0017); the layout, the Frame, Panels, forms, navigation, pagination and popovers mirror.

## What mirrors
- **Layout**: Frame (sidebar and corners on the right), Panel, Nav, Tabs, Breadcrumb, Pagination, FormActions, Table alignment, `Bar` caps.
- **Elbow**: use the logical corners `top_start`, `top_end`, `bottom_start`, `bottom_end`; they mirror with the direction. The physical names
  (`top_left`...) never mirror, for a shape that must stay on one side.
- **Frame slots**: `with_top_start_corner` / `with_bottom_start_corner` (the old `with_*_left_corner` names still work). Panel `corners: :start`
  (or `:left`) closes the side where the text starts.
- **Icons that point a direction** (chevrons) are flipped. Other icons are not.
- **Slider fill** starts on the side where the value starts. **Tooltip and Menu** open aligned on the side where the text starts.

## What stays left to right
Data: a Readout's number and unit, and a Clock, are isolated as left-to-right text inside an RTL page, so "72.4 kW" and "18.4 °C" keep their characters
in order. The Readout row itself still follows the page direction (number on the right, unit on its left).

## Checked
`spec/system/rtl_spec.rb` (corner shapes, icons, slider, popovers, data), a pixel check that text-free shapes in RTL equal the flipped LTR render
(`spec/visual/rtl_mirror_spec.rb`), and RTL screenshots in `bin/visual --dir rtl --themes classic --widths 768`. Open any Lookbook preview with
`?dir=rtl` to see it.

## Not covered
No translations (`ar`, `he`); the strings are `en` and `fr`. Text inside your own content is yours to mark up (`dir`, `lang`). A page was not tested with a
screen reader in RTL. Data order (Sparkline, BarGraph) is the data's and does not mirror.
