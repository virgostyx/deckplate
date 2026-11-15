module Deckplate
  module Forms
    # Native date/time controls. Date, Time and String values are formatted the way the control expects.
    class DateInputComponent < ControlComponent
      TYPES = { date: "date", time: "time", datetime_local: "datetime-local", month: "month", week: "week" }.freeze
      FORMATS = { date: "%Y-%m-%d", time: "%H:%M", datetime_local: "%Y-%m-%dT%H:%M", month: "%Y-%m", week: "%G-W%V" }.freeze

      def initialize(type: :date, value: nil, **options)
        super(**options)
        @type = type.to_s.to_sym
        raise ArgumentError, "invalid type #{type.inspect}; valid: #{TYPES.keys.join(', ')}" unless TYPES.key?(@type)

        @value = value.respond_to?(:strftime) ? value.strftime(FORMATS.fetch(@type)) : value
      end

      private

      def html_type = TYPES.fetch(@type)
    end
  end
end
