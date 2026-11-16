module Deckplate
  module Feedback
    # "Nothing here yet": a title, a hint and an action.
    class EmptyStateComponent < BaseComponent
      include Concerns::Headed

      renders_one :action, ->(&block) { tag.div(class: "dp-empty-state__action", &block) }

      def self.block_name = "dp-empty-state"

      def initialize(title:, hint: nil, icon: nil, level: 2, **html_options)
        super(**html_options)
        @title = validate_title!(title)
        @level = validate_level!(level)
        raise ArgumentError, "unknown icon #{icon.inspect}; valid: #{Helpers::ICONS.keys.join(', ')}" if icon && !Helpers::ICONS.key?(icon.to_sym)

        @hint = hint
        @icon = icon&.to_sym
      end

      private

      def state_attributes = html_attributes(classes: [ block_name ])
    end
  end
end
