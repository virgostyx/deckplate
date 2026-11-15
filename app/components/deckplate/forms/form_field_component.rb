module Deckplate
  module Forms
    # Label + hint + control + errors with the right for/id/aria-describedby wiring. Controls render their own FormField.
    # `as: :fieldset` renders fieldset/legend for groups (radios). `label: nil` when the control draws its own label.
    class FormFieldComponent < BaseComponent
      include Concerns::Describable

      AS = %i[div fieldset].freeze

      def self.block_name = "dp-field" # shorter than the derived dp-form-field

      def initialize(control_id:, label:, hint: nil, errors: nil, required: false, alert: false, as: :div, **html_options)
        super(**html_options)
        raise ArgumentError, "control_id is required" if control_id.to_s.strip.empty?
        raise ArgumentError, "invalid as #{as.inspect}; valid: #{AS.join(', ')}" unless AS.include?(as.to_s.to_sym)

        @field_id = control_id.to_s
        @label = label
        @hint = hint
        @errors = normalize_errors(errors)
        @required = required
        @alert = alert
        @as = as.to_sym
      end

      private

      def fieldset? = @as == :fieldset

      def field_attributes
        html_attributes(
          classes: [ block_name, ("dp-field--invalid" if invalid?) ],
          aria: (fieldset? ? { describedby: describedby_ids }.compact : {})
        )
      end
    end
  end
end
