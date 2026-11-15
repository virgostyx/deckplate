module Deckplate
  module Shapes
    # Segmented rule. `segments:` is a count (all segments in `color:`) or an array with one colour per segment.
    class DividerComponent < BaseComponent
      def initialize(color: :primary, segments: 1, **html_options)
        super(**html_options)
        @colors = normalize(segments, color)
      end

      private

      def normalize(segments, color)
        case segments
        when Integer
          raise ArgumentError, "segments must be >= 1, got #{segments}" if segments < 1

          Array.new(segments, resolve_color(color))
        when Array
          raise ArgumentError, "segments must not be empty" if segments.empty?

          segments.map { |c| resolve_color(c) }
        else
          raise ArgumentError, "segments must be an Integer or an Array of colours, got #{segments.inspect}"
        end
      end
    end
  end
end
