module Deckplate
  # An item of a Menu: a link, or a button posting a form when `method:` is given (like button_to).
  class MenuItemComponent < BaseComponent
    def initialize(label:, href:, method: nil, **html_options)
      super(**html_options)
      raise ArgumentError, "label is required" if label.to_s.strip.empty?
      raise ArgumentError, "href is required" if href.to_s.strip.empty?

      @label = label
      @href = href
      @http_method = method&.to_sym unless method.to_s == "get"
    end

    private

    def item_attributes
      html_attributes(classes: [ "dp-menu__item" ], role: "menuitem", tabindex: -1, data: { action: "click->dp-menu#close" })
    end
  end
end
