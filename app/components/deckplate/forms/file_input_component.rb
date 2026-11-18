module Deckplate
  module Forms
    # Native file input inside a FormField. `accept:` is the usual accept string, `multiple: true` allows several files.
    class FileInputComponent < ControlComponent
      def initialize(accept: nil, multiple: false, **options)
        super(**options)
        @accept = accept
        @multiple = multiple
      end
    end
  end
end
