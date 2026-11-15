module Deckplate
  # Short description shown on hover and focus of the wrapped trigger (dp-tooltip). Never put essential information in it.
  class TooltipComponent < BaseComponent
    def initialize(text:, **html_options)
      super(**html_options)
      raise ArgumentError, "text is required" if text.to_s.strip.empty?

      @text = text
    end

    private

    def tooltip_id = @html_options[:id].presence || "#{@text.to_s.parameterize}-tooltip"

    def host_attributes
      html_attributes(classes: [ block_name ], data: {
        controller: "dp-tooltip",
        action: "mouseenter->dp-tooltip#show mouseleave->dp-tooltip#hide focusin->dp-tooltip#show focusout->dp-tooltip#hide keydown->dp-tooltip#key"
      }).except(:id)
    end
  end
end
