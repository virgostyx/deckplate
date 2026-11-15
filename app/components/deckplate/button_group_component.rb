module Deckplate
  # Stacked or inline row of buttons sharing the group role.
  class ButtonGroupComponent < BaseComponent
    variant :orientation, %i[horizontal vertical], default: :horizontal

    def initialize(orientation: nil, label: nil, **html_options)
      super(**html_options)
      assign_variants(orientation:)
      @label = label
    end

    private

    def group_attributes
      html_attributes(classes: [ block_name, *variant_classes ], role: "group", aria: { label: @label }.compact)
    end
  end
end
