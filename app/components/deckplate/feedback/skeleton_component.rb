module Deckplate
  module Feedback
    # Placeholder shapes while content loads. One status text for assistive technology; the shapes are hidden from it.
    class SkeletonComponent < BaseComponent
      variant :shape, %i[text block circle], default: :text

      def self.block_name = "dp-skeleton"

      def initialize(lines: 1, shape: nil, label: nil, **html_options)
        super(**html_options)
        raise ArgumentError, "lines must be an Integer from 1 to 20 (got #{lines.inspect})" unless lines.is_a?(Integer) && (1..20).cover?(lines)
        raise ArgumentError, "label must not be empty" if !label.nil? && label.to_s.strip.empty?

        assign_variants(shape:)
        @lines = lines
        @label = label
      end

      private

      def text = @label || t("deckplate.common.loading")
      def skeleton_attributes = html_attributes(classes: [ block_name, *variant_classes ], role: "status")
    end
  end
end
