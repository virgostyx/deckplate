module Deckplate
  module Concerns
    # Components with a visible heading: a required title and a validated heading level (1-6).
    module Headed
      private

      def validate_title!(title)
        raise ArgumentError, "title is required (got #{title.inspect})" if title.to_s.strip.empty?

        title
      end

      def validate_level!(level)
        raise ArgumentError, "level must be an Integer from 1 to 6, got #{level.inspect}" unless level.is_a?(Integer) && (1..6).cover?(level)

        level
      end

      # id of the heading when the caller gave the component an id (keeps rendering deterministic), else nil
      def heading_id
        "#{@html_options[:id]}-title" if @html_options[:id].present?
      end
    end
  end
end
