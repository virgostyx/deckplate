module Deckplate
  module Data
    # A ticking clock (dp-clock). The text is rendered on the server (the initial value); the controller then updates it
    # every second from the *server's* epoch, so a wrong client clock does not matter, and pauses while the tab is hidden.
    # `role="timer"` is not a live region: assistive technology does not announce every second.
    # Not render-pure by nature: `time:` defaults to the current time (pass one to get stable output).
    class ClockComponent < BaseComponent
      FORMATS = { time: "%H:%M:%S", datetime: "%Y-%m-%d %H:%M:%S", date: "%Y-%m-%d" }.freeze

      def self.block_name = "dp-clock"

      def initialize(time: nil, format: :time, zone: nil, label: nil, **html_options)
        super(**html_options)
        raise ArgumentError, "invalid format #{format.inspect}; valid: #{FORMATS.keys.join(', ')}" unless FORMATS.key?(format.to_s.to_sym)

        @zone = zone ? ActiveSupport::TimeZone[zone] : Time.zone
        raise ArgumentError, "unknown zone #{zone.inspect} (use a tz database name such as \"Europe/Brussels\")" unless @zone

        @format = format.to_s.to_sym
        @time = time || Time.current
        @label = label
      end

      private

      def local = @time.in_time_zone(@zone)

      def clock_attributes
        html_attributes(
          classes: [ block_name ], role: "timer", datetime: @time.utc.iso8601, aria: { label: @label }.compact,
          data: { controller: "dp-clock", dp_clock_epoch_value: (@time.to_i * 1000), dp_clock_zone_value: @zone.tzinfo.name, dp_clock_format_value: @format }
        )
      end
    end
  end
end
