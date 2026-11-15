module Deckplate
  module Shapes
    # One coloured block inside a Bar (slot of BarComponent). Without `color:` it inherits the bar's colour.
    class BarSegmentComponent < BaseComponent
      def initialize(color: nil, size: nil, **html_options)
        super(**html_options)
        @color = resolve_color(color) if color
        u(size) if size # validates
        @size = size
      end
    end
  end
end
