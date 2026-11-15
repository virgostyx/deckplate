module Deckplate
  module Forms
    # A Slider (native range + live readout) inside a FormField: hint and errors are linked to the range input.
    # The slider draws its own label, and `required` does not apply to a range (the browser always has a value).
    class RangeComponent < ControlComponent
      def initialize(min: 0, max: 100, step: 1, value: nil, unit: nil, show_value: true, color: :primary, **options)
        super(**options)
        @slider = { min:, max:, step:, value:, unit:, show_value:, color: }
      end

      private

      def field_options = super.merge(label: nil, required: false)

      def input_html
        html_attributes(classes: [], aria: { invalid: ("true" if invalid?), describedby: describedby_ids }.compact)
          .slice(:class, :data, :aria).merge(@html_options.except(:class, :data, :aria, :id))
          .tap { |h| h[:class] = Array(h[:class]) }
      end
    end
  end
end
