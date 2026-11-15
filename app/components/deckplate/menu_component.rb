module Deckplate
  # Menu button pattern (dp-menu) on a native popover. Items are links or form buttons.
  class MenuComponent < BaseComponent
    renders_many :items, "Deckplate::MenuItemComponent"

    def initialize(label:, color: :primary, **html_options)
      super(**html_options)
      raise ArgumentError, "label is required" if label.to_s.strip.empty?

      @label = label
      @color = resolve_color(color)
    end

    def before_render
      content # evaluates the block, which defines the items
      raise ArgumentError, "a menu needs at least one item" if items.empty?
    end

    private

    def menu_id = @html_options[:id].presence || "#{@label.to_s.parameterize}-menu"

    def host_attributes
      html_attributes(classes: [ block_name, color_class(@color) ], data: { controller: "dp-menu", action: "turbo:before-morph-attribute->dp-menu#keepState" }).except(:id)
    end
  end
end
