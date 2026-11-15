module Deckplate
  # View helpers, included in every ActionView (see Deckplate::Engine).
  module Helpers
    PRELOADED_FONTS = %w[antonio-latin share-tech-mono-latin].freeze

    # <link rel="preload"> tags for the two latin fonts. Put it in <head>, before the stylesheet.
    def dp_font_tags
      safe_join(PRELOADED_FONTS.map do |name|
        tag.link(rel: "preload", href: asset_path("deckplate/#{name}.woff2"), as: "font", type: "font/woff2", crossorigin: "anonymous")
      end, "\n")
    end
  end
end
