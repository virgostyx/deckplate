# Minimal concrete components used to exercise BaseComponent and its concerns.
module Deckplate
  class DemoComponent < BaseComponent
    variant :size, %i[sm md lg], default: :md
    variant :shape, %i[pill block], default: :pill

    def initialize(color: nil, size: nil, shape: nil, **html_options)
      super(**html_options)
      @color = resolve_color(color, default: :primary) if color
      assign_variants(size:, shape:)
    end

    def call
      tag.div("demo", **html_attributes(classes: [ block_name, *variant_classes, (color_class(@color) if @color) ]))
    end
  end
end
