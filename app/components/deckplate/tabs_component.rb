module Deckplate
  # WAI-ARIA tabs pattern (dp-tabs): roving tabindex, arrows / Home / End, automatic activation.
  # Server-rendered with the selected tab visible; without JavaScript only that tab is usable.
  class TabsComponent < BaseComponent
    renders_many :tabs, "Deckplate::TabComponent"

    def initialize(selected: nil, label: nil, color: :primary, hash: false, **html_options)
      super(**html_options)
      @selected = selected&.to_s
      @label = label
      @color = resolve_color(color)
      @hash = hash
    end

    def before_render
      content # evaluates the block, which defines the tabs
      raise ArgumentError, "at least one tab is required" if tabs.empty?

      ids = tabs.map(&:tab_id)
      dup = ids.tally.find { |_, n| n > 1 }&.first
      raise ArgumentError, "tab ids must be unique (duplicate: #{dup.inspect})" if dup
      raise ArgumentError, "selected #{@selected.inspect} is not one of the tab ids #{ids.inspect}" if @selected && !ids.include?(@selected)

      current = @selected || ids.first
      tabs.each { |tab| tab.selected = (tab.tab_id == current) }
    end

    private

    def tabs_attributes
      html_attributes(classes: [ block_name, color_class(@color) ],
                      data: { controller: "dp-tabs", action: "turbo:before-morph-attribute->dp-tabs#keepState", dp_tabs_hash_value: (true if @hash) }.compact)
    end
  end
end
