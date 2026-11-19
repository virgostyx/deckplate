require "zlib"
require "pathname"

module DeckplateBuild
  # Size budgets of SPEC section 12 (ADR 0009, 0011, 0012). Raise a limit only together with an ADR.
  # CSS is measured per sheet (what a host that picks families loads) and for the all-in-one file.
  class Budgets
    KB = 1024
    # name => [raw limit, gzip limit] in KB
    CSS_LIMITS = { "core" => [ 50, 9 ], "controls" => [ 25, 5 ], "forms" => [ 25, 5 ], "data" => [ 25, 5 ], "feedback" => [ 25, 5 ], "all-in-one" => [ 120, 20 ] }.freeze

    Row = Struct.new(:name, :size, :limit) do
      def ok? = size <= limit
    end

    def initialize(root)
      @root = Pathname(root)
    end

    def rows
      css_rows + js_rows + [ Row.new("Fonts (woff2)", Dir[@root.join("app/assets/fonts/deckplate/*.woff2")].sum { File.size(_1) }, 90 * KB) ]
    end

    def report
      rows.map { |r| format("  %-22s %7.1f KB / %5.1f KB  %s", r.name, r.size / 1024.0, r.limit / 1024.0, r.ok? ? "ok" : "OVER BUDGET") }.join("\n")
    end

    private

    def css_rows
      CSS_LIMITS.flat_map do |name, (raw_kb, gzip_kb)|
        file = name == "all-in-one" ? "deckplate.css" : "deckplate-#{name}.css"
        css = @root.join("app/assets/stylesheets", file).binread
        [ Row.new("CSS #{name} raw", css.bytesize, raw_kb * KB), Row.new("CSS #{name} gzip", gzip(css), gzip_kb * KB) ]
      end
    end

    def js_rows
      js = Dir[@root.join("app/javascript/**/*.js")].sort.map { File.binread(_1) }.join("\n")
      [ Row.new("JS raw", js.bytesize, 40 * KB), Row.new("JS gzip", gzip(js), 12 * KB) ]
    end

    def gzip(data) = Zlib.gzip(data, level: 9).bytesize
  end
end
