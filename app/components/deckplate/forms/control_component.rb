module Deckplate
  module Forms
    # Base of the form controls: name, derived id, label, hint, errors, required/disabled, and the ARIA wiring.
    # Subclasses provide a template that calls `render_field { ... }` around the native control.
    # `**html_options` go to the native control (class, data, aria, placeholder, min/max, ...), not to the wrapper.
    class ControlComponent < BaseComponent
      include Concerns::Describable

      def initialize(name:, label:, hint: nil, errors: nil, required: false, disabled: false, alert: false, **html_options)
        super(**html_options)
        raise ArgumentError, "name is required" if name.to_s.strip.empty?
        raise ArgumentError, "label is required (a control needs an accessible name)" if label.to_s.strip.empty?

        @name = name.to_s
        @label = label
        @hint = hint
        @errors = normalize_errors(errors)
        @required = required
        @disabled = disabled
        @alert = alert
        @field_id = html_options[:id].presence || derive_id(@name)
      end

      private

      def field_options
        { control_id: @field_id, label: @label, hint: @hint, errors: @errors, required: @required, alert: @alert }
      end

      # Wraps the control in a FormField (label, hint, errors).
      def render_field(**overrides, &block)
        render(FormFieldComponent.new(**field_options, **overrides), &block)
      end

      # Attributes of the native control: id, name, state, and aria-invalid / aria-describedby wired to the field.
      def control_attributes(css: "dp-input", **own)
        html_attributes(
          classes: [ css ],
          aria: { invalid: ("true" if invalid?), describedby: describedby_ids }.compact,
          id: @field_id, name: @name, required: @required.presence, disabled: @disabled.presence, **own
        )
      end
    end
  end
end
