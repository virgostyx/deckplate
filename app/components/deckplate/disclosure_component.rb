module Deckplate
  # Native <details>/<summary>: no JavaScript.
  class DisclosureComponent < BaseComponent
    def initialize(summary:, open: false, color: :secondary, **html_options)
      super(**html_options)
      raise ArgumentError, "summary is required" if summary.to_s.strip.empty?

      @summary = summary
      @open = open
      @color = resolve_color(color)
    end

    private

    def disclosure_attributes = html_attributes(classes: [ block_name, color_class(@color) ])
  end
end
