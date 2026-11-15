module Deckplate
  # Page links for server-side pagination. `url_for` is a callable: ->(page) { "/ships?page=#{page}" }.
  # No dependency on Pagy or Kaminari: pass their page/count values (adapters are documented in the guides).
  class PaginationComponent < BaseComponent
    def initialize(page:, pages:, url_for:, window: 2, **html_options)
      super(**html_options)
      raise ArgumentError, "pages must be an Integer >= 1, got #{pages.inspect}" unless pages.is_a?(Integer) && pages >= 1
      raise ArgumentError, "page must be an Integer between 1 and #{pages}, got #{page.inspect}" unless page.is_a?(Integer) && (1..pages).cover?(page)
      raise ArgumentError, "url_for must respond to call (e.g. a lambda taking the page number)" unless url_for.respond_to?(:call)
      raise ArgumentError, "window must be an Integer >= 0, got #{window.inspect}" unless window.is_a?(Integer) && window >= 0

      @page, @pages, @url_for, @window = page, pages, url_for, window
    end

    def render? = @pages > 1

    private

    # [1, :gap, 9, 10, 11, :gap, 20]; a gap of exactly one page shows that page instead of an ellipsis
    def entries
      shown = ([ 1, @pages ] + ((@page - @window)..(@page + @window)).to_a).select { (1..@pages).cover?(_1) }.uniq.sort
      shown.each_cons(2).with_object([ shown.first ]) do |(a, b), out|
        out << (b - a == 2 ? a + 1 : :gap) if b - a > 1
        out << b
      end
    end

    def nav_attributes
      html_attributes(classes: [ block_name ], aria: { label: t("deckplate.pagination.label") })
    end

    def url(page) = @url_for.call(page)
  end
end
