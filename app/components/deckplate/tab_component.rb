module Deckplate
  # One tab and its panel (slot of TabsComponent). The parent renders the tab button and sets `selected`.
  class TabComponent < BaseComponent
    attr_reader :label, :tab_id
    attr_writer :selected

    def initialize(label:, id:, **html_options)
      super(**html_options)
      raise ArgumentError, "tab label is required" if label.to_s.strip.empty?
      raise ArgumentError, "tab id is required (it builds the tab and panel ids)" if id.to_s.strip.empty?

      @label = label
      @tab_id = id.to_s
      @selected = false
    end

    def selected? = @selected

    private

    def panel_attributes
      html_attributes(classes: [ "dp-tabs__panel" ], aria: { labelledby: "#{@tab_id}-tab" },
                      data: { dp_tabs_target: "panel" })
    end
  end
end
