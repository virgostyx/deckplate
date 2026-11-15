module Deckplate
  module Layout
    # Titled block inside a Panel or page. With an `id:` the section is named by its heading.
    class SectionComponent < BaseComponent
      include Concerns::Headed

      def initialize(title:, color: :secondary, level: 2, **html_options)
        super(**html_options)
        @title = validate_title!(title)
        @color = resolve_color(color)
        @level = validate_level!(level)
      end

      private

      def section_attributes
        html_attributes(classes: [ block_name, color_class(@color) ], aria: { labelledby: heading_id })
      end
    end
  end
end
