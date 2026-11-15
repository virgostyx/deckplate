module Deckplate
  class Configuration
    BUILT_IN_THEMES = %i[classic azure nocturne daylight crimson].freeze
    THEME_NAME = /\A[a-z][a-z0-9]*(-[a-z0-9]+)*\z/

    attr_reader :default_theme, :themes
    attr_accessor :sounds, :csp_safe_values, :strict_colors, :form_builder

    def initialize
      @themes = BUILT_IN_THEMES
      @default_theme = :classic
      @sounds = false
      @csp_safe_values = false
      @strict_colors = defined?(Rails) ? Rails.env.local? : true
      @form_builder = false
    end

    def themes=(list)
      @themes = Array(list).map { |t| normalize_theme(t) }.freeze
    end

    def default_theme=(name)
      @default_theme = normalize_theme(name)
    end

    def validate!
      return if themes.include?(default_theme)
      raise ArgumentError, "default_theme #{default_theme.inspect} is not in themes (#{themes.join(', ')})"
    end

    private

    def normalize_theme(name)
      raise ArgumentError, "invalid theme name #{name.to_s.inspect} (use lowercase letters, digits and hyphens)" unless name.to_s.match?(THEME_NAME)
      name.to_sym
    end
  end
end
