require "view_component"
require "deckplate/version"
require "deckplate/configuration"
require "deckplate/engine"
require "deckplate/form_builder"

module Deckplate
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the configuration; if the result is invalid the previous configuration is kept and ArgumentError is raised.
    def configure
      candidate = configuration.dup
      yield candidate
      candidate.validate!
      @configuration = candidate
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
