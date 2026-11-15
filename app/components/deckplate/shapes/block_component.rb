module Deckplate
  module Shapes
    # Rectangular labelled block: the building block of navigation and readouts.
    class BlockComponent < BaseComponent
      TAGS = %i[div span li].freeze

      variant :shape, %i[square pill start end], default: :square
      variant :align, %i[start center end], default: :end, prefix: true

      def initialize(color: :primary, shape: nil, align: nil, number: nil, tag: :div, **html_options)
        super(**html_options)
        assign_variants(shape:, align:)
        @color = resolve_color(color)
        @number = number
        raise ArgumentError, "invalid tag #{tag.inspect}; valid: #{TAGS.join(', ')}" unless TAGS.include?(tag.to_s.to_sym)

        @tag = tag.to_sym
      end

      private

      def block_attributes
        html_attributes(classes: [ block_name, *variant_classes, color_class(@color) ])
      end
    end
  end
end
