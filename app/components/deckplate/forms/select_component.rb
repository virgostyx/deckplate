module Deckplate
  module Forms
    # Native <select>. options: ["A", ["Label", "value"], :sym] or { "Group" => [...] }. include_blank: true | "Prompt".
    class SelectComponent < ControlComponent
      def initialize(options:, value: nil, include_blank: false, **html)
        super(**html)
        raise ArgumentError, "options is required (an Array or a Hash of groups)" if options.blank?

        @options = options
        @value = value
        @include_blank = include_blank
      end

      private

      def pairs(list) = list.map { |o| o.is_a?(Array) ? [ o[0].to_s, o[1].to_s ] : [ o.to_s, o.to_s ] }

      def blank_pair
        text = @include_blank == true ? t("deckplate.forms.select_prompt") : @include_blank.to_s
        [ [ text, "" ] ]
      end

      def options_html
        selected = @value.to_s
        if @options.is_a?(Hash)
          groups = @options.transform_values { |list| pairs(list) }
          safe_join([ (helpers.options_for_select(blank_pair, selected) if @include_blank), helpers.grouped_options_for_select(groups, selected) ].compact)
        else
          helpers.options_for_select((@include_blank ? blank_pair : []) + pairs(@options), selected)
        end
      end
    end
  end
end
