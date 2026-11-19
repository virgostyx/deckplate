# ADR 0020 — Sortable list: buttons for everyone, a drag as a shortcut

Status: accepted (Phase 9)

## Context
Reordering by drag and drop is common, and a pointer drag alone fails keyboard, switch and screen-reader users. WCAG 2.2 criterion 2.5.7 (Dragging
Movements) requires a single-pointer alternative to any drag. HTML5 drag and drop does not work on touch screens.

## Decisions
1. **Every item has real "move up" and "move down" buttons**, named after the item ("Move Alpha up"). They work with keyboard, touch and screen readers, and need
   no mode to learn. The first item's up button and the last item's down button are disabled.
2. **A pointer drag on a grip is only a shortcut.** It uses pointer events (mouse, touch and pen), with the pointer captured on the list, which never moves: moving
   the dragged node would release a capture held on it. The grip is `aria-hidden` and has `touch-action: none`.
3. **The DOM order is the order.** With `name:`, each item carries a hidden input, so a plain form submits the order; `dp-sortable:reorder` carries `{ ids }` for
   scripts and Turbo. The component never touches the database.
4. **Announcements**: a polite live region says "Alpha moved to position 2 of 3"; focus stays on the button used (or on its twin when that one becomes disabled).
5. **No script, no controls**: the buttons and the grip only appear once the controller sets `data-dp-sortable-ready`; the list stays a plain ordered list.
6. Not done: no grab-with-Space keyboard mode (the buttons cover it), no nested lists, no dragging between lists, no persistence (the app saves the order).

## Consequences
Specs: component structure, i18n, validation; browser checks for buttons, focus, form fields, the event, the announcement, the pointer drag, RTL. The controller
weighs about 1.2 KB gzip, which led to ADR 0021.
