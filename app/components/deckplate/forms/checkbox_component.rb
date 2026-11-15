module Deckplate
  module Forms
    # One checkbox whose label sits next to the box. `unchecked_value:` adds a hidden field like Rails' check_box.
    class CheckboxComponent < ControlComponent
      def initialize(checked: false, value: "1", unchecked_value: nil, **options)
        super(**options)
        @checked = checked
        @value = value
        @unchecked_value = unchecked_value
      end

      private

      def field_options = super.merge(label: nil)
    end
  end
end
