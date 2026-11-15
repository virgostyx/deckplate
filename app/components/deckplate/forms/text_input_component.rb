module Deckplate
  module Forms
    class TextInputComponent < ControlComponent
      TYPES = %i[text email password number search tel url].freeze

      def initialize(type: :text, value: nil, **options)
        super(**options)
        @type = type.to_s.to_sym
        raise ArgumentError, "invalid type #{type.inspect}; valid: #{TYPES.join(', ')}" unless TYPES.include?(@type)

        # a password is never written back into the page
        @value = value unless @type == :password
      end
    end
  end
end
