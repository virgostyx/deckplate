module Deckplate
  # On/off switch: a native checkbox with role="switch", styled with CSS only (no JavaScript).
  # `unchecked_value:` adds a hidden field so an unchecked switch still submits a value (like Rails' check_box).
  class ToggleComponent < BaseComponent
    def initialize(name:, label: nil, checked: false, value: "1", unchecked_value: nil, disabled: false, color: :success, **html_options)
      super(**html_options)
      raise ArgumentError, "name is required" if name.to_s.strip.empty?

      @name = name
      @label = label
      @checked = checked
      @value = value
      @unchecked_value = unchecked_value
      @disabled = disabled
      @color = resolve_color(color)
    end

    def before_render
      raise ArgumentError, "label: or a block is required (a switch needs an accessible name)" if @label.blank? && !content?
    end

    private

    def label_classes = [ "dp-toggle", color_class(@color), ("dp-toggle--disabled" if @disabled) ]
    def input_attributes = html_attributes(classes: [ "dp-toggle__input" ])
  end
end
