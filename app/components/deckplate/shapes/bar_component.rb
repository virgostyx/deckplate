module Deckplate
  module Shapes
    # Horizontal or vertical bar, optionally capped and/or made of coloured segments.
    # Decorative (aria-hidden) unless it carries text (title or segment content).
    class BarComponent < BaseComponent
      variant :orientation, %i[horizontal vertical], default: :horizontal
      variant :caps, %i[none start end both], default: :none

      renders_one :title, ->(&block) { tag.span(class: "dp-bar__title", &block) }
      renders_many :segments, "Deckplate::Shapes::BarSegmentComponent"

      def initialize(orientation: nil, color: :primary, caps: nil, thickness: nil, fill: false, **html_options)
        super(**html_options)
        assign_variants(orientation:, caps:)
        @color = resolve_color(color)
        u(thickness) if thickness # validates
        @thickness = thickness
        @fill = fill
      end

      private

      def decorative?
        !title? && segments.none?(&:content?)
      end

      def bar_attributes
        html_attributes(
          classes: [ block_name, *variant_classes, color_class(@color), ("dp-bar--fill" if @fill) ],
          style: (@thickness && "--dp-bar-t: #{@thickness}"),
          aria: (decorative? ? { hidden: true } : {})
        )
      end
    end
  end
end
