module Deckplate
  module Data
    # A labelled value in monospaced tabular figures. The caller formats the value; a trend is an icon plus a text.
    # Give it an `id:` so that a Turbo Stream can replace it.
    class ReadoutComponent < BaseComponent
      TRENDS = { up: :chevron_up, down: :chevron_down, flat: :minus }.freeze

      def initialize(label:, value:, unit: nil, trend: nil, color: :info, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required" if label.to_s.strip.empty?
        raise ArgumentError, "invalid trend #{trend.inspect}; valid: #{TRENDS.keys.join(', ')}" if trend && !TRENDS.key?(trend.to_sym)

        @label = label
        @value = value
        @unit = unit
        @trend = trend&.to_sym
        @color = resolve_color(color)
      end

      private

      def readout_attributes = html_attributes(classes: [ block_name, color_class(@color) ])
      def blank_value? = @value.nil? || @value.to_s.strip.empty?
    end
  end
end
