module Deckplate
  # Short description shown on hover and focus of the wrapped trigger (dp-tooltip). Never put essential information in it.
  class TooltipComponent < BaseComponent
    PLACEMENTS = %i[top bottom start end].freeze

    # placement: preferred side (:start and :end follow the text direction); the bubble flips to the opposite side when it does not fit.
    # delay: milliseconds before a hover opens it (keyboard focus always opens at once).
    def initialize(text:, placement: :bottom, delay: 0, **html_options)
      super(**html_options)
      raise ArgumentError, "text is required" if text.to_s.strip.empty?
      raise ArgumentError, "placement must be one of #{PLACEMENTS.inspect} (got #{placement.inspect})" unless PLACEMENTS.include?(placement&.to_sym)
      raise ArgumentError, "delay must be an Integer >= 0, in milliseconds (got #{delay.inspect})" unless delay.is_a?(Integer) && delay >= 0

      @text = text
      @placement = placement.to_sym
      @delay = delay
    end

    private

    def tooltip_id = @html_options[:id].presence || "#{@text.to_s.parameterize}-tooltip"

    def host_attributes
      html_attributes(classes: [ block_name ], data: {
        controller: "dp-tooltip",
        dp_tooltip_placement_value: @placement,
        dp_tooltip_delay_value: @delay,
        action: "mouseenter->dp-tooltip#show mouseleave->dp-tooltip#hide focusin->dp-tooltip#show focusout->dp-tooltip#hide keydown->dp-tooltip#key"
      }).except(:id)
    end
  end
end
