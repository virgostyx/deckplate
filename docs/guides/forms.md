# Forms

Deckplate ships native-element form controls and a form builder that wires labels, hints, errors and required markers for you.

## With the form builder

```erb
<%= form_with model: @profile, builder: Deckplate::FormBuilder do |f| %>
  <%= f.dp_text_field :callsign, hint: "Between 3 and 20 characters" %>
  <%= f.dp_email_field :email %>
  <%= f.dp_text_area :bio, rows: 4 %>
  <%= f.dp_select :role, [["Explorer", "explorer"], ["Medic", "medic"]], include_blank: true %>
  <%= f.dp_check_box :shields, label: "Raise shields" %>
  <%= f.dp_radio_group :contact, [["Comms", "comms"], ["Courier", "courier"]] %>
  <%= f.dp_range :clearance, min: 0, max: 100, step: 5, unit: "%" %>
  <%= f.dp_date_field :birthday %>
  <%= f.dp_file_field :avatar, accept: "image/*" %>
  <%= f.dp_actions do %>
    <%= f.dp_submit %>
    <%= render Deckplate::ButtonComponent.new(label: "Cancel", href: profiles_path, color: :muted) %>
  <% end %>
<% end %>
```

Make it the default builder for every form with `config.form_builder = true` in `config/initializers/deckplate.rb`.

What the builder reads from your model (anything `ActiveModel`, no database needed):

| Part | Source |
|---|---|
| Label | `helpers.label.<model>.<attribute>` (I18n), else `Model.human_attribute_name` |
| Hint | `helpers.hint.<model>.<attribute>` (I18n), or the `hint:` option |
| Errors | `model.errors[attribute]` |
| Required marker + `required` attribute | an unconditional `validates ..., presence: true` (override with `required:`) |
| Value | `model.public_send(attribute)` (never written back for passwords) |

`f.dp_check_box` submits `"0"` when unchecked, like Rails' `check_box` (`unchecked_value:` to change it). `fields_for` keeps the
builder, and nested names and ids follow Rails (`ship[crew_attributes][0][name]`).

## Without a model

Every control is a component taking `name:` and `label:`:

```erb
<%= render Deckplate::Forms::TextInputComponent.new(name: "search[q]", label: "Query", value: params.dig(:search, :q)) %>
```

The id is derived from the name (`search_q`) and the label, hint and error ids from the id, so the markup is deterministic.
Options you pass (`class:`, `data:`, `placeholder:`, `min:`, ...) go to the **native control**, not to the wrapper.

## Errors, 422 and focus

Re-render the form with status 422 after a failed validation and redirect with 303 after success; Turbo does the rest:

```ruby
if @profile.save
  redirect_to @profile, status: :see_other, notice: "Saved."
else
  render :new, status: :unprocessable_entity
end
```

* Every invalid control gets `aria-invalid="true"` and `aria-describedby` pointing at its messages, shown with an icon and a text
  prefix (never colour alone).
* Only the **first** invalid field is a `role="alert"` and receives the focus, also when the app uses
  `turbo_refreshes_with method: :morph` (ADR 0008).
* Put `novalidate` on the form (`html: { novalidate: true }`) if you want the server messages instead of the browser's.

## Turbo morph

With `turbo_refreshes_with method: :morph`, a page refresh does not erase what the user is typing: a field they touched keeps its
value, checked and selected state until the form is submitted. A field they did not touch follows the server.

## Accessibility notes

* The required marker `*` is hidden from assistive technology; a text alternative ("required") is read instead.
* Radios are a `<fieldset>` with a `<legend>`; the hint and errors describe the group.
* Disabled controls are drawn with a dashed outline and muted text (not a filled colour), and stay legible in every theme.
* The date control is the browser's own: in Chrome it has four tab stops (month, day, year, calendar button).

## Keypad

```erb
<%= render Deckplate::Forms::KeypadComponent.new(name: "pin", label: "Access code", length: 4, masked: true, submit: "Unlock") %>
```

A code or number field with an on-screen pad (1-9, clear, 0, delete). It is a real `<input inputmode="numeric">` inside a FormField (label, hint, errors,
`required`, `disabled` as for the other controls), so the physical keyboard works, anything that is not a digit is dropped, and the value is submitted with the form;
the pad only fills the input in. `length:` (1 to 12) fixes the digit count (`maxlength` and a `pattern`), `masked: true` makes it a password field (the value is never
written back into the page), `submit:` adds a submit button with that label. The keys are Buttons, so link `deckplate-controls` with `deckplate-forms`.

Assistive technology: the keys are real buttons with names ("Clear", "Delete last digit"); a polite live region announces "Digits entered: N", never the digits, so a masked
code stays secret. Every change fires an `input` event, which is how `dp-field` keeps the entered code through a Turbo morph.

## Not in v1.0

`select multiple`, checkbox groups, client-side (inline) validation, rich text. See the backlog in `docs/PLAN.md`.
