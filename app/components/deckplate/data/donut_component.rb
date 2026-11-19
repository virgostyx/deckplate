module Deckplate
  module Data
    # Share of a whole as a ring, computed on the server as inline SVG (no JavaScript, no style attribute). The drawing is
    # decorative: every slice is also named, with its value and share, in the legend and in a visually hidden table.
    class DonutComponent < BaseComponent
      COLORS = %i[primary info success warning accent secondary tertiary danger].freeze
      GAP = 0.5 # between slices, in hundredths of the ring

      def self.block_name = "dp-donut"

      # series: [[name, value], ...] with values >= 0 and a total > 0. center: [text, caption] replaces the total in the middle.
      def initialize(label:, series:, center: nil, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (it names the chart)" if label.to_s.strip.empty?
        raise ArgumentError, "series must not be empty" if series.blank?
        raise ArgumentError, "center must be [text, caption] (got #{center.inspect})" unless center.nil? || (center.is_a?(Array) && center.size == 2)

        @label = label
        @series = series.to_a.map { |entry| normalize(entry) }
        @total = @series.sum(&:last)
        raise ArgumentError, "the total of the values must be greater than 0" unless @total.positive?

        @center = center&.map(&:to_s)
      end

      private

      def normalize(entry)
        text, value = entry
        raise ArgumentError, "a series entry needs a label (got #{entry.inspect})" if text.to_s.strip.empty?
        raise ArgumentError, "a series value must be a number >= 0 (got #{value.inspect} for #{text.inspect})" unless value.is_a?(Numeric) && !value.negative?

        [ text.to_s, value ]
      end

      def center_text = @center || [ fmt(@total), t("deckplate.data.graph_total") ]
      def fmt(number) = (number == number.to_i ? number.to_i : number)
      def percent(value) = (value * 100.0 / @total).round
      def color_for(index) = color_class(COLORS[index % COLORS.size])

      # Drawn slices with their length and start along a ring of length 100 (pathLength), zero values left out.
      def slices
        start = 0.0
        @series.each_with_index.filter_map do |(_, value), i|
          share = value * 100.0 / @total
          slice = { index: i, length: (@series.count { _2.positive? } > 1 ? [ share - GAP, 0.01 ].max : share).round(2), offset: -start.round(2) } if value.positive?
          start += share
          slice
        end
      end

      def donut_attributes = html_attributes(classes: [ block_name ])
    end
  end
end
