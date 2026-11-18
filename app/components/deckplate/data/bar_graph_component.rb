module Deckplate
  module Data
    # Server-rendered bar graph. The bars are decorative; the same data is in a visually hidden table (screen readers).
    # With keys:, each item has one value per key ([["Mon", [10, 20]], ...]) shown side by side (grouping: :grouped) or as
    # consecutive segments of one bar (grouping: :stacked). Keys are told apart by colour, pattern and legend name.
    class BarGraphComponent < BaseComponent
      KEY_COLORS = %i[primary info success warning].freeze

      variant :orientation, %i[horizontal vertical], default: :horizontal
      variant :grouping, %i[grouped stacked], default: :grouped

      def initialize(label:, series:, max: nil, orientation: nil, grouping: nil, keys: nil, color: :primary, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (it names the graph)" if label.to_s.strip.empty?
        raise ArgumentError, "series must not be empty" if series.blank?
        raise ArgumentError, "max must be a number > 0 (got #{max.inspect})" unless max.nil? || (max.is_a?(Numeric) && max.positive?)

        assign_variants(orientation:, grouping:)
        raise ArgumentError, "keys must be a list of names, one per value (got #{keys.inspect})" unless keys.nil? || (keys.is_a?(Array) && keys.any? && keys.none? { _1.to_s.strip.empty? })

        @label = label
        @keys = keys&.map(&:to_s)
        @series = series.to_a.map { |entry| normalize(entry) }
        @max = max || [ scale_values.max, 1 ].max
        @color = resolve_color(color)
      end

      private

      def normalize(entry)
        text, value = entry
        raise ArgumentError, "a series entry needs a label (got #{entry.inspect})" if text.to_s.strip.empty?

        if @keys
          raise ArgumentError, "the values of #{text.inspect} must be #{@keys.size} numbers >= 0, one per key (got #{value.inspect})" unless value.is_a?(Array) && value.size == @keys.size && value.all? { _1.is_a?(Numeric) && !_1.negative? }
        else
          raise ArgumentError, "keys is required when a series has several values (got #{value.inspect} for #{text.inspect})" if value.is_a?(Array)
          raise ArgumentError, "a series value must be a number >= 0 (got #{value.inspect} for #{text.inspect})" unless value.is_a?(Numeric) && !value.negative?
        end

        [ text.to_s, value ]
      end

      def multi? = !@keys.nil?
      def stacked? = @variants[:grouping] == :stacked
      def total(values) = values.sum
      def scale_values = multi? ? (stacked? ? @series.map { total(_1.last) } : @series.flat_map(&:last)) : @series.map(&:last)

      # The graph's own colour first, then the others, so a single colour choice still leads.
      def key_color(index)
        palette = [ @color ] + (KEY_COLORS - [ @color ])
        palette[index % palette.size]
      end

      def key_classes(index) = [ "dp-bar-graph__bar--k#{index % 4}", color_class(key_color(index)) ]
      def key_bar_attributes(value, index) = dynamic_attributes(classes: [ "dp-bar-graph__bar", *key_classes(index) ], percent: [ value.to_f / @max * 100, 100 ].min)

      def graph_attributes = html_attributes(classes: [ block_name, *variant_classes, color_class(@color) ])
      def bar_attributes(value) = dynamic_attributes(classes: [ "dp-bar-graph__bar" ], percent: [ value.to_f / @max * 100, 100 ].min)
    end
  end
end
