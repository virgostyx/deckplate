module Deckplate
  module Shapes
    # Transparent gap sized in layout units (multiples of --dp-u).
    class SpacerComponent < BaseComponent
      variant :axis, %i[block inline], default: :block

      def initialize(size: 1, axis: nil, **html_options)
        super(**html_options)
        u(size) # validates: a non-negative number
        @size = size
        assign_variants(axis:)
      end
    end
  end
end
