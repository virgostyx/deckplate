module Deckplate
  module Data
    # Line chart with axes, computed on the server as inline SVG (no JavaScript, no style attribute). The drawing is decorative;
    # the same data is in a visually hidden table. Lines differ by colour, dash pattern and legend name.
    class LineChartComponent < BaseComponent
      WIDTH = 480
      HEIGHT = 240
      LEFT = 44
      RIGHT = 12
      TOP = 12
      BOTTOM = 28
      MAX_X_LABELS = 8
      DASHES = [ nil, "6 3", "2 3" ].freeze
      COLORS = %i[primary info success warning].freeze

      def self.block_name = "dp-line-chart"

      # series: [[name, [values]], ...], one value per entry of x_labels. threshold: [label, value] draws a limit line.
      def initialize(label:, x_labels:, series:, area: false, threshold: nil, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (it names the chart)" if label.to_s.strip.empty?
        raise ArgumentError, "x_labels must be an Array of at least 2 labels (got #{x_labels.inspect})" unless x_labels.is_a?(Array) && x_labels.size >= 2
        raise ArgumentError, "series must be a non-empty Array of [name, values] (got #{series.inspect})" unless series.is_a?(Array) && series.any?
        raise ArgumentError, "threshold must be [label, number] (got #{threshold.inspect})" unless threshold.nil? || (threshold.is_a?(Array) && threshold.size == 2 && threshold.last.is_a?(Numeric))

        @label = label
        @x_labels = x_labels.map(&:to_s)
        @series = series.map { |entry| normalize(entry) }
        @area = area
        @threshold = threshold && [ threshold.first.to_s, threshold.last ]
        compute_axis
      end

      private

      def normalize(entry)
        name, values = entry
        raise ArgumentError, "a series needs a name (got #{entry.inspect})" if name.to_s.strip.empty?
        raise ArgumentError, "values of #{name.inspect} must be #{@x_labels.size} numbers, one per x label (got #{values.inspect})" unless values.is_a?(Array) && values.size == @x_labels.size && values.all?(Numeric)

        [ name.to_s, values ]
      end

      # Round-number ticks (1, 2, 5 times a power of ten) that cover the data, zero and the threshold.
      def compute_axis
        all = @series.flat_map(&:last) + [ @threshold&.last ].compact
        low = [ all.min, 0 ].min
        high = [ all.max, 0 ].max
        high = low + 1 if high == low
        raw = (high - low) / 4.0
        magnitude = 10.0**Math.log10(raw).floor
        step = [ 1, 2, 5, 10 ].find { |m| raw / magnitude <= m } * magnitude
        @low = (low / step).floor * step
        @high = (high / step).ceil * step
        @ticks = (0..((@high - @low) / step).round).map { |i| (@low + i * step).round(10) }
      end

      def plot_width = WIDTH - LEFT - RIGHT
      def plot_height = HEIGHT - TOP - BOTTOM
      def x_at(index) = (LEFT + index.fdiv(@x_labels.size - 1) * plot_width).round(2)
      def y_at(value) = (TOP + (1 - (value - @low).fdiv(@high - @low)) * plot_height).round(2)

      def line_points(values) = values.each_with_index.map { |value, i| "#{x_at(i)},#{y_at(value)}" }.join(" ")

      def area_points(values) = "#{x_at(0)},#{y_at(@low)} #{line_points(values)} #{x_at(@x_labels.size - 1)},#{y_at(@low)}"

      def visible_x_labels
        every = (@x_labels.size.fdiv(MAX_X_LABELS)).ceil
        @x_labels.each_with_index.select { |_, i| (i % every).zero? }
      end

      def color_for(index) = COLORS[index % COLORS.size]
      def dash_for(index) = DASHES[index % DASHES.size]

      def fmt(number) = (number == number.to_i ? number.to_i : number)

      def chart_attributes = html_attributes(classes: [ block_name ])
      def series_attributes(index) = { class: [ "dp-line-chart__series", color_class(color_for(index)) ].join(" ") }
    end
  end
end
