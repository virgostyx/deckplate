module Deckplate
  module Shapes
    # Half-pill end piece. `start` is the left end, `end` the right end (left-to-right layouts only, see SPEC non-goals).
    class CapComponent < BaseComponent
      variant :side, %i[start end], default: :end

      def initialize(side: nil, color: :primary, **html_options)
        super(**html_options)
        assign_variants(side:)
        @color = resolve_color(color)
      end
    end
  end
end
