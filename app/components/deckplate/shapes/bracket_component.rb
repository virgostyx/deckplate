module Deckplate
  module Shapes
    # Open frame around content: a coloured rule on some sides only. start = left, end = right (left-to-right layouts).
    class BracketComponent < BaseComponent
      SIDES = %i[top bottom start end].freeze

      def initialize(sides: %i[start end], color: :primary, **html_options)
        super(**html_options)
        @sides = Array(sides).map(&:to_sym)
        raise ArgumentError, "sides must not be empty (valid: #{SIDES.join(', ')})" if @sides.empty?

        (@sides - SIDES).each { |s| raise ArgumentError, "invalid side #{s.inspect}; valid: #{SIDES.join(', ')}" }
        @color = resolve_color(color)
      end

      private

      def bracket_attributes
        html_attributes(classes: [ block_name, *@sides.uniq.map { "#{block_name}--#{_1}" }, color_class(@color) ])
      end
    end
  end
end
