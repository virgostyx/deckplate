module Deckplate
  module Concerns
    # Colours are Symbols: a semantic role (:primary) or a palette stop (:neon_carrot). Underscores in Ruby, hyphens in CSS.
    module Colorable
      ROLES = %i[primary secondary tertiary accent muted info success warning danger emergency].freeze

      def self.palette_stops
        @palette_stops ||= YAML.load_file(Deckplate::Engine.root.join("config/deckplate/palette.yml"))
                               .fetch("stops").keys.map { |name| name.tr("-", "_").to_sym }.freeze
      end

      def self.valid_colors
        @valid_colors ||= (ROLES + palette_stops).freeze
      end

      # Returns a valid colour Symbol. Invalid input raises (strict_colors) or logs and falls back to `default`.
      def self.resolve(value, default: :primary)
        sym = value.respond_to?(:to_sym) ? value.to_sym : nil
        return sym if sym && valid_colors.include?(sym)

        message = "unknown colour #{value.inspect}; valid: #{valid_colors.map(&:inspect).join(', ')}"
        raise ArgumentError, message if Deckplate.configuration.strict_colors

        Rails.logger.warn("[Deckplate] #{message}; falling back to :#{default}")
        default
      end

      def self.css_class(color)
        "dp-c-#{color.to_s.tr('_', '-')}"
      end

      private

      def resolve_color(value, default: :primary) = Colorable.resolve(value, default:)

      def color_class(color) = Colorable.css_class(color)
    end
  end
end
