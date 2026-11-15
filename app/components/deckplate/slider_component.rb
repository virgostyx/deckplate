module Deckplate
  # Native range input with a live value readout (dp-slider). The value stays available to assistive tech through the input.
  class SliderComponent < BaseComponent
    def initialize(name:, label:, min: 0, max: 100, step: 1, value: nil, show_value: true, unit: nil, disabled: false, color: :primary, **html_options)
      super(**html_options)
      raise ArgumentError, "name is required" if name.to_s.strip.empty?
      raise ArgumentError, "label is required (a slider needs an accessible name)" if label.to_s.strip.empty?
      raise ArgumentError, "min (#{min}) must be lower than max (#{max})" unless min < max
      raise ArgumentError, "step must be > 0, got #{step}" unless step.positive?

      value = min if value.nil?
      raise ArgumentError, "value #{value} is outside #{min}..#{max}" unless (min..max).cover?(value)

      @name, @label, @min, @max, @step, @value = name, label, min, max, step, value
      @show_value = show_value
      @unit = unit
      @disabled = disabled
      @color = resolve_color(color)
    end

    private

    def input_id = @html_options[:id].presence || "#{@name.to_s.parameterize}-slider"

    def wrapper_attributes
      html_attributes(
        classes: [ block_name, color_class(@color), ("dp-slider--disabled" if @disabled) ],
        data: { controller: "dp-slider", dp_slider_unit_value: @unit }.compact,
        id: nil
      ).except(:id)
    end

    def readout = "#{@value}#{@unit}"
  end
end
