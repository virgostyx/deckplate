require "zlib"
require "pathname"

module DeckplateBuild
  # Size budgets of SPEC section 12. Raise a limit only together with an ADR.
  class Budgets
    Row = Struct.new(:name, :size, :limit) do
      def ok? = size <= limit
    end

    def initialize(root)
      @root = Pathname(root)
    end

    def rows
      css = @root.join("app/assets/stylesheets/deckplate.css").binread
      js = Dir[@root.join("app/javascript/**/*.js")].sort.map { File.binread(_1) }.join("\n")
      fonts = Dir[@root.join("app/assets/fonts/deckplate/*.woff2")].sum { File.size(_1) }
      [ Row.new("CSS raw", css.bytesize, 60 * 1024), Row.new("CSS gzip", gzip(css), 12 * 1024),
        Row.new("JS raw", js.bytesize, 20 * 1024), Row.new("JS gzip", gzip(js), 6 * 1024),
        Row.new("Fonts (woff2)", fonts, 90 * 1024) ]
    end

    def report
      rows.map { |r| format("  %-14s %7.1f KB / %5.1f KB  %s", r.name, r.size / 1024.0, r.limit / 1024.0, r.ok? ? "ok" : "OVER BUDGET") }.join("\n")
    end

    private

    def gzip(data) = Zlib.gzip(data, level: 9).bytesize
  end
end
