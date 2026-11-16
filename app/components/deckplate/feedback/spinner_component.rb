module Deckplate
  module Feedback
    # Segmented-bars loader. A status region with a text alternative; the bars are decorative.
    class SpinnerComponent < BaseComponent
      variant :size, %i[sm md lg], default: :md

      def self.block_name = "dp-spinner"

      def initialize(size: nil, color: :primary, label: nil, show_label: false, **html_options)
        super(**html_options)
        assign_variants(size:)
        raise ArgumentError, "label must not be empty" if !label.nil? && label.to_s.strip.empty?

        @color = resolve_color(color)
        @label = label
        @show_label = show_label
      end

      private

      def text = @label || t("deckplate.common.loading")
      def spinner_attributes = html_attributes(classes: [ block_name, *variant_classes, color_class(@color) ], role: "status")
    end
  end
end
