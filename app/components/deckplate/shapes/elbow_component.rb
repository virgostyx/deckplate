module Deckplate
  module Shapes
    # Signature elbow: a coloured block with an outer arc and a transparent inner arc (ADR 0002, technique A2).
    # Corners: physical (top_left...) never mirror; logical (top_start, top_end, bottom_start, bottom_end) mirror with the text direction (ADR 0017).
    # Decorative (aria-hidden) unless a label is given. CSS knobs: --dp-elbow-w/-h (overall), --dp-elbow-col (vertical arm),
    # --dp-elbow-bar (horizontal arm), --dp-elbow-r (outer radius), --dp-elbow-ri (inner radius).
    class ElbowComponent < BaseComponent
      variant :corner, %i[top_left top_right bottom_left bottom_right top_start top_end bottom_start bottom_end], default: :top_left
      variant :size, %i[sm md lg], default: :md

      renders_one :label, ->(&block) { tag.span(class: "dp-elbow__label", &block) }

      def initialize(corner: nil, color: :primary, size: nil, width: nil, height: nil, **html_options)
        super(**html_options)
        assign_variants(corner:, size:)
        @color = resolve_color(color)
        @width = width && u(width)
        @height = height && u(height)
      end

      private

      def elbow_attributes
        html_attributes(
          classes: [ block_name, *variant_classes, color_class(@color) ],
          vars: { "--dp-elbow-w": @width, "--dp-elbow-h": @height }.compact,
          aria: (label? ? {} : { hidden: true })
        )
      end
    end
  end
end
