module Deckplate
  module Forms
    class TextareaComponent < ControlComponent
      def initialize(value: nil, rows: 4, **options)
        super(**options)
        @value = value
        @rows = rows
      end
    end
  end
end
