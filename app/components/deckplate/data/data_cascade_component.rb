module Deckplate
  module Data
    # Decorative columns of numbers (aria-hidden, animated by CSS, still under prefers-reduced-motion).
    # The numbers come from a seeded generator, so the same inputs always give the same HTML.
    class DataCascadeComponent < BaseComponent
      def self.block_name = "dp-data-cascade"

      def initialize(columns: 8, rows: 6, digits: 4, seed: 1, color: :warning, **html_options)
        super(**html_options)
        raise ArgumentError, "columns must be an Integer from 1 to 40 (got #{columns.inspect})" unless columns.is_a?(Integer) && (1..40).cover?(columns)
        raise ArgumentError, "rows must be an Integer from 1 to 100 (got #{rows.inspect})" unless rows.is_a?(Integer) && (1..100).cover?(rows)
        raise ArgumentError, "digits must be an Integer from 1 to 9 (got #{digits.inspect})" unless digits.is_a?(Integer) && (1..9).cover?(digits)

        random = Random.new(seed)
        @grid = Array.new(columns) { Array.new(rows) { random.rand(10**digits).to_s.rjust(digits, "0") } }
        @color = resolve_color(color)
      end

      private

      def cascade_attributes = html_attributes(classes: [ block_name, color_class(@color) ], aria: { hidden: true })
    end
  end
end
