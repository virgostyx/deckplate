module Deckplate
  # Native range input with a live value readout (dp-slider). The value stays available to assistive tech through the input.
  class SliderComponent < BaseComponent
    def initialize(name:, label:, min: 0, max: 100, step: 1, value: nil, show_value: true, unit: nil, disabled: false, color: :primary, input_html: {}, **html_options)
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
      @input_html = input_html
      @color = resolve_color(color)
    end

    private

    def input_id = @html_options[:id].presence || "#{@name.to_s.parameterize}-slider"

    def wrapper_attributes
      html_attributes(
        classes: [ block_name, color_class(@color), ("dp-slider--disabled" if @disabled) ],
        data: { controller: "dp-slider", action: "turbo:before-morph-attribute->dp-slider#keepState turbo:morph-element->dp-slider#update", dp_slider_unit_value: @unit }.compact,
        id: nil
      ).except(:id)
    end

    # The native input: defaults + caller's input_html (class appended, data/aria merged, other attributes win)
    def input_attributes
      extra = @input_html.except(:class, :data, :aria)
      {
        type: "range", id: input_id, name: @name, min: @min, max: @max, step: @step, value: @value, disabled: @disabled,
        class: [ "dp-slider__input", *Array(@input_html[:class]) ],
        data: merge_data({ dp_slider_target: "input", action: "input->dp-slider#update" }, @input_html[:data] || {}),
        aria: merge_tokens({}, @input_html[:aria] || {}, TOKEN_ARIA_KEYS)
      }.merge(extra).compact_blank
    end

    def readout = "#{@value}#{@unit}"
  end
end
