module Deckplate
  module Data
    # Server-rendered bar graph. The bars are decorative; the same data is in a visually hidden table (screen readers).
    class BarGraphComponent < BaseComponent
      variant :orientation, %i[horizontal vertical], default: :horizontal

      def initialize(label:, series:, max: nil, orientation: nil, color: :primary, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (it names the graph)" if label.to_s.strip.empty?
        raise ArgumentError, "series must not be empty" if series.blank?
        raise ArgumentError, "max must be a number > 0 (got #{max.inspect})" unless max.nil? || (max.is_a?(Numeric) && max.positive?)

        assign_variants(orientation:)
        @label = label
        @series = series.to_a.map { |entry| normalize(entry) }
        @max = max || [ @series.map(&:last).max, 1 ].max
        @color = resolve_color(color)
      end

      private

      def normalize(entry)
        text, value = entry
        raise ArgumentError, "a series entry needs a label (got #{entry.inspect})" if text.to_s.strip.empty?
        raise ArgumentError, "a series value must be a number >= 0 (got #{value.inspect} for #{text.inspect})" unless value.is_a?(Numeric) && !value.negative?

        [ text.to_s, value ]
      end

      def graph_attributes = html_attributes(classes: [ block_name, *variant_classes, color_class(@color) ])
      def bar_attributes(value) = dynamic_attributes(classes: [ "dp-bar-graph__bar" ], percent: [ value.to_f / @max * 100, 100 ].min)
    end
  end
end
