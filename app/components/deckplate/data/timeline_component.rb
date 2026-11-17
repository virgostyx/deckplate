module Deckplate
  module Data
    # Vertical timeline of events as an ordered list: `with_event(title:, time: nil, datetime: nil, state: :done, color: nil) { body }`.
    # Each event is done (a check in its marker), current (aria-current="step") or upcoming (hollow marker); the state is never colour alone:
    # a shape or icon, and a visually hidden text for assistive technology. `time:` is a text or a Time (shown as "YYYY-MM-DD HH:MM", with its
    # ISO 8601 value in `datetime`). The timeline has a colour role; one event may take another.
    class TimelineComponent < BaseComponent
      STATES = %i[done current upcoming].freeze

      renders_many :events, ->(title:, time: nil, datetime: nil, state: :done, color: nil, &block) {
        event_html(title:, time:, datetime:, state:, color:, &block)
      }

      def self.block_name = "dp-timeline"

      def initialize(color: :primary, **html_options)
        super(**html_options)
        @color = resolve_color(color)
      end

      private

      def list_attributes = html_attributes(classes: [ block_name, color_class(@color) ])

      def event_html(title:, time:, datetime:, state:, color:, &block)
        raise ArgumentError, "an event needs a title (got #{title.inspect})" if title.to_s.strip.empty?

        state = state.to_s.to_sym
        raise ArgumentError, "invalid state #{state.inspect}; valid: #{STATES.join(', ')}" unless STATES.include?(state)
        raise ArgumentError, "datetime needs a time (the text shown for it)" if datetime && time.nil?

        classes = [ "dp-timeline__event", "dp-timeline__event--#{state}", (color_class(resolve_color(color)) if color) ]
        tag.li(class: classes, aria: { current: ("step" if state == :current) }.compact) do
          safe_join([ marker(state), tag.div(class: "dp-timeline__content") { safe_join([ title_html(title, state), time_html(time, datetime), body_html(&block) ].compact) } ])
        end
      end

      def marker(state)
        tag.span(state == :done ? helpers.dp_icon(:check) : nil, class: "dp-timeline__marker", aria: { hidden: true })
      end

      def title_html(title, state)
        tag.p(class: "dp-timeline__title") { safe_join([ title, tag.span(": #{t("deckplate.timeline.states.#{state}")}", class: "dp-sr-only") ]) }
      end

      def time_html(time, datetime)
        return if time.nil?

        if time.respond_to?(:strftime)
          tag.time(time.strftime("%Y-%m-%d %H:%M"), class: "dp-timeline__time", datetime: time.respond_to?(:iso8601) ? time.iso8601 : nil)
        else
          tag.time(time.to_s, class: "dp-timeline__time", datetime: datetime)
        end
      end

      def body_html(&block)
        tag.div(class: "dp-timeline__body", &block) if block
      end
    end
  end
end
