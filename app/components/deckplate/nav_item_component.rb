module Deckplate
  # One link of a Nav or TopNav. `current: nil` detects the current page with current_page?.
  class NavItemComponent < BaseComponent
    def initialize(label:, href:, color: :tertiary, number: nil, current: nil, **html_options)
      super(**html_options)
      raise ArgumentError, "label is required" if label.to_s.strip.empty?
      raise ArgumentError, "href is required" if href.to_s.strip.empty?

      @label = label
      @href = href
      @color = resolve_color(color)
      @number = number
      @current = current
    end

    private

    def current?
      return @current unless @current.nil?

      helpers.current_page?(@href)
    rescue ArgumentError, NoMethodError
      false
    end

    def link_attributes
      html_attributes(classes: [ "dp-nav__link", color_class(@color), ("dp-nav__link--current" if current?) ],
                      aria: { current: ("page" if current?) }.compact)
    end
  end
end
