module Deckplate
  module Concerns
    # Numeric sizes are multiples of the layout unit --dp-u (never px, so zoom scales the console).
    module Sizeable
      private

      def u(number)
        raise ArgumentError, "size must be a number of layout units, got #{number.inspect}" unless number.is_a?(Numeric)
        raise ArgumentError, "size must be >= 0 (no negative sizes), got #{number}" if number.negative?

        "calc(#{number} * var(--dp-u))"
      end
    end
  end
end
