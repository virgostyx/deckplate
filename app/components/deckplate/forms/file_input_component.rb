module Deckplate
  module Forms
    class FileInputComponent < ControlComponent
      def initialize(accept: nil, multiple: false, **options)
        super(**options)
        @accept = accept
        @multiple = multiple
      end
    end
  end
end
