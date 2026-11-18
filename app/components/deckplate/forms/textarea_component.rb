module Deckplate
  module Forms
    # Native <textarea> inside a FormField: `value:` is the current text, `rows:` the visible height (default 4).
    class TextareaComponent < ControlComponent
      def initialize(value: nil, rows: 4, **options)
        super(**options)
        @value = value
        @rows = rows
      end
    end
  end
end
