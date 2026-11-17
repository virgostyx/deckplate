module Deckplate
  module Layout
    # Grouped content: a coloured header bar with a title, a body, and an optional footer bar.
    # corners: :left / :both closes the panel with elbows and rails (the signature C-shape) instead of plain bars.
    class PanelComponent < BaseComponent
      include Concerns::Headed

      variant :corners, %i[none left both], default: :none

      renders_one :header_actions, ->(&block) { tag.div(class: "dp-panel__actions", &block) }
      renders_one :footer

      def initialize(title:, color: :primary, corners: nil, level: 2, **html_options)
        super(**html_options)
        @title = validate_title!(title)
        @color = resolve_color(color)
        @level = validate_level!(level)
        assign_variants(corners: (corners&.to_sym == :start ? :left : corners)) # :start is the logical name of :left
      end

      private

      def cornered? = variants[:corners] != :none
      def both? = variants[:corners] == :both
      def footer_bar? = footer? || cornered?

      def panel_attributes
        html_attributes(classes: [ block_name, *variant_classes, color_class(@color) ], aria: { labelledby: heading_id })
      end

      def elbow(corner)
        render Shapes::ElbowComponent.new(corner:, color: @color, class: "dp-panel__elbow")
      end
    end
  end
end
