module Deckplate
  # items: [["Home", "/"], ["Ships", "/ships"], ["Aurora"]] or [{label:, href:}, ...]. The last item is the current page.
  class BreadcrumbComponent < BaseComponent
    def initialize(items:, **html_options)
      super(**html_options)
      raise ArgumentError, "items must not be empty" if Array(items).empty?

      @items = items.map { |item| normalize(item) }
    end

    private

    def normalize(item)
      label, href = case item
      when Array then item
      when Hash then item.values_at(:label, :href)
      else raise ArgumentError, "invalid breadcrumb item #{item.inspect} (use [label, href] or {label:, href:})"
      end
      raise ArgumentError, "breadcrumb item needs a label (got #{item.inspect})" if label.to_s.strip.empty?

      { label: label, href: href }
    end

    def nav_attributes
      html_attributes(classes: [ block_name ], aria: { label: t("deckplate.breadcrumb.label") })
    end
  end
end
