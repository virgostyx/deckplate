# Feedback

`Deckplate::Feedback::` holds the components that tell the user what is happening: `AlertComponent`, `ConditionBannerComponent`,
`ToastComponent` (with `dp_toast_container`), `SpinnerComponent`, `SkeletonComponent`, `EmptyStateComponent`, `CalloutComponent`.

## Toasts with Turbo Streams

Put the container once in your layout, then append toasts from any response:

```erb
<%# app/views/layouts/application.html.erb %>
<%= dp_toast_container %>
```

```ruby
# any controller action answering a form submission or a button_to
render turbo_stream: turbo_stream.append("dp-toasts",
  Deckplate::Feedback::ToastComponent.new(kind: :success).with_content("Profile saved."))
```

The container is a `role="region"` **polite live region that exists before any toast**: that is what makes the added toasts announced by
assistive technology (a live region created together with its content is often missed). Its markup is checked in
`spec/helpers/deckplate/toast_container_spec.rb`; the behaviour in `spec/system/feedback_spec.rb`.

| Kind | Role | Default duration |
|---|---|---|
| `:info`, `:success` | `status` (polite) | 5 seconds |
| `:warning`, `:danger` | `alert` (assertive) | stays until dismissed (`0`) |

Warnings and errors stay because the user must be able to read them (WCAG 2.2.1); pass `duration:` (milliseconds) to change this.
The countdown **pauses while the pointer is over the toast or a control inside it has the focus**, and resumes after.
The stack is capped by `dp_toast_container(max: 3)` (default 5): the oldest toast is removed first.

### Flash messages

Render the flash inside the container so that it uses the same markup:

```erb
<%= dp_toast_container do %>
  <% flash.each do |type, message| %>
    <%= render Deckplate::Feedback::ToastComponent.new(kind: type == "alert" ? :danger : :success).with_content(message) %>
  <% end %>
<% end %>
```

### Turbo morph

With `turbo_refreshes_with method: :morph` a page refresh re-renders the container from the server's (empty) markup and **removes the toasts
that were appended by streams**. Pick one:

* `dp_toast_container(permanent: true)`: the container and its toasts survive refreshes and visits. The trade-off: Turbo ignores the new
  page's version of a permanent element, so toasts rendered from the *next* page's flash are not shown. Use it when messages arrive through
  streams only.
* the default (not permanent): flash toasts work with every visit, but a morph refresh clears the current toasts.

## Alert

`AlertComponent.new(kind: :warning, title: "Heads up", dismissible: true)`. `info` and `success` are `role="status"`, `warning` and `danger`
`role="alert"`. The kind is an icon and a visually hidden word as well as a colour. The close button (`dp-dismiss`) removes the alert and moves
the focus to the next focusable element, so keyboard users are not sent back to the top of the page.

## ConditionBanner

`ConditionBannerComponent.new(condition: :critical)` (`:normal`, `:caution`, `:critical`). The text and an icon are always present.
The critical banner is an alert, carries a **static hazard-stripe marker** (the cue that does not depend on motion), pulses, and switches to
the `crimson` theme when your app enables it. The pulse is off under `prefers-reduced-motion`.

## The others

* `SpinnerComponent`: a `role="status"` region with a text ("Loading", or `label:`); `show_label: true` shows it.
* `SkeletonComponent`: placeholder shapes (`lines:`, `shape: :text/:block/:circle`), hidden from assistive technology, with one status text.
* `EmptyStateComponent`: `title:`, `hint:`, an `action` slot, an optional decorative `icon:`.
* `CalloutComponent`: a `role="note"` highlight inside running text (`:note`, `:tip`, `:warning`).

All animations (spinner, skeleton shimmer, banner pulse) stop under `prefers-reduced-motion`.
