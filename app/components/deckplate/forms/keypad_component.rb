module Deckplate
  module Forms
    # A code or number field with an on-screen keypad (1-9, clear, 0, delete). The field is a real <input inputmode="numeric">: the physical
    # keyboard works, the value is submitted with the form, and the pad only fills it in (dp-keypad). A polite live region announces how many
    # digits there are, never which (so a masked code is not leaked). `length:` fixes the digit count, `masked: true` hides the digits
    # (type=password: the value is never written back into the page), `submit:` adds a submit button with that label.
    class KeypadComponent < ControlComponent
      MAX_LENGTH = 12
      DIGITS = %w[1 2 3 4 5 6 7 8 9].freeze

      def initialize(length: nil, masked: false, value: nil, submit: nil, color: :primary, **options)
        super(**options)
        raise ArgumentError, "length must be an Integer from 1 to #{MAX_LENGTH}, got #{length.inspect}" unless length.nil? || (length.is_a?(Integer) && length.between?(1, MAX_LENGTH))
        raise ArgumentError, "submit must be a button label, not blank" if !submit.nil? && submit.to_s.strip.empty?

        @length = length
        @masked = masked
        @value = value unless masked # a masked code is never echoed back into the page
        @submit = submit
        @color = resolve_color(color)
      end

      private

      def pattern = @length ? "[0-9]{#{@length}}" : "[0-9]*"

      def keypad_attributes
        { class: "dp-keypad", data: { controller: "dp-keypad", dp_keypad_status_template_value: t("deckplate.keypad.status", number: "%{count}") } }
      end

      def input_attributes
        control_attributes(css: "dp-input dp-keypad__input", data: { dp_keypad_target: "input", action: "input->dp-keypad#sanitize" },
                           inputmode: "numeric", autocomplete: "off", pattern: pattern, maxlength: @length)
      end

      def key(digit)
        render ButtonComponent.new(label: digit, color: @color, disabled: @disabled, class: "dp-keypad__key",
                                   data: { action: "dp-keypad#press", dp_keypad_digit_param: digit })
      end

      def clear_key
        render ButtonComponent.new(label: "C", color: :muted, disabled: @disabled, class: "dp-keypad__key",
                                   aria: { label: t("deckplate.keypad.clear") }, data: { action: "dp-keypad#clear" })
      end

      def delete_key
        render(ButtonComponent.new(icon: :backspace, color: :muted, disabled: @disabled, class: "dp-keypad__key",
                                   aria: { label: t("deckplate.keypad.delete") }, data: { action: "dp-keypad#backspace" })) do
          tag.span(t("deckplate.keypad.delete"), class: "dp-sr-only")
        end
      end
    end
  end
end
