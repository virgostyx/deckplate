module Deckplate
  module Data
    # Radial or semicircular gauge (role="meter"), pure CSS. value: 0..100. Give it an `id:` so a Turbo Stream can replace it.
    class GaugeComponent < BaseComponent
      variant :variant, %i[radial semicircle], default: :radial

      def initialize(label:, value:, variant: nil, unit: "%", color: :info, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (a meter needs an accessible name)" if label.to_s.strip.empty?
        raise ArgumentError, "value must be a number from 0 to 100 (got #{value.inspect})" unless value.is_a?(Numeric) && (0..100).cover?(value)

        assign_variants(variant:)
        @label = label
        @value = value
        @unit = unit
        @color = resolve_color(color)
      end

      private

      def number = (@value == @value.to_i ? @value.to_i : @value)

      def gauge_attributes
        html_attributes(
          classes: [ block_name, *variant_classes, color_class(@color) ],
          percent: @value,
          role: "meter",
          aria: { label: @label, valuemin: 0, valuemax: 100, valuenow: number, valuetext: "#{number}#{@unit}" }
        )
      end
    end
  end
end
