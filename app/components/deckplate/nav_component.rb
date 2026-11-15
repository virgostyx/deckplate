module Deckplate
  # Main (sidebar) navigation: a nav landmark with a list of NavItems.
  class NavComponent < BaseComponent
    renders_many :items, "Deckplate::NavItemComponent"

    def initialize(label: nil, **html_options)
      super(**html_options)
      @label = label
    end

    private

    def nav_attributes
      html_attributes(classes: [ block_name ], aria: { label: @label.presence || t("deckplate.nav.label") })
    end
  end
end
