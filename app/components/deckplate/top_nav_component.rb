module Deckplate
  # Secondary, tab-like links (sections of the current area). Not an ARIA tablist: these are real links.
  class TopNavComponent < BaseComponent
    renders_many :items, "Deckplate::NavItemComponent"

    def initialize(label: nil, **html_options)
      super(**html_options)
      @label = label
    end

    private

    def nav_attributes
      html_attributes(classes: [ block_name ], aria: { label: @label.presence || t("deckplate.top_nav.label") })
    end
  end
end
