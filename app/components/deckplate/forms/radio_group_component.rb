module Deckplate
  module Forms
    # Radios in a fieldset: the label is the legend. options: ["A", ["Label", "value"]]. layout: :stack | :inline.
    class RadioGroupComponent < ControlComponent
      variant :layout, %i[stack inline], default: :stack

      def initialize(options:, value: nil, layout: nil, **html)
        super(**html)
        raise ArgumentError, "options is required (at least one choice)" if options.blank?

        @choices = options.map { |o| o.is_a?(Array) ? [ o[0].to_s, o[1].to_s ] : [ o.to_s, o.to_s ] }
        @value = value.to_s
        assign_variants(layout:)
      end

      private

      def field_options = super.merge(as: :fieldset)

      def group_attributes = html_attributes(classes: [ block_name, *variant_classes ], id: nil).except(:id)

      def radio_id(value) = "#{@field_id}_#{value.parameterize(separator: '_')}"

      def radio_attributes(value)
        { aria: { invalid: ("true" if invalid?) }.compact, id: radio_id(value), name: @name, required: @required.presence, disabled: @disabled.presence }
      end
    end
  end
end
