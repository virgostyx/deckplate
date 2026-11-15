module Deckplate
  module Data
    # Tiny trend line as an inline SVG polyline, computed on the server (no style attribute, no JavaScript).
    class SparklineComponent < BaseComponent
      WIDTH = 100.0
      HEIGHT = 30.0
      MARGIN = 1.0

      def self.block_name = "dp-sparkline"

      def initialize(label:, points:, color: :info, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (it names the trend)" if label.to_s.strip.empty?
        raise ArgumentError, "points must be an Array of at least 2 numbers (got #{points.inspect})" unless points.is_a?(Array) && points.size >= 2 && points.all?(Numeric)

        @label = label
        @points = points
        @color = resolve_color(color)
      end

      private

      def coordinates
        low, high = @points.minmax
        span = high - low
        @points.each_with_index.map do |value, i|
          x = i.fdiv(@points.size - 1) * WIDTH
          y = span.zero? ? HEIGHT / 2 : HEIGHT - MARGIN - (value - low).fdiv(span) * (HEIGHT - 2 * MARGIN)
          "#{x.round(2)},#{y.round(2)}"
        end.join(" ")
      end

      def fmt(number) = (number == number.to_i ? number.to_i : number)

      def summary
        low, high = @points.minmax
        t("deckplate.data.sparkline", label: @label, first: fmt(@points.first), last: fmt(@points.last), min: fmt(low), max: fmt(high))
      end

      def svg_attributes
        html_attributes(classes: [ block_name, color_class(@color) ], role: "img", focusable: "false",
                        viewBox: "0 0 #{WIDTH.to_i} #{HEIGHT.to_i}", preserveAspectRatio: "none", aria: { label: summary })
      end
    end
  end
end
