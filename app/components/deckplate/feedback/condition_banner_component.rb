module Deckplate
  module Feedback
    # Ship-wide condition. Text and icon always; critical is an alert, pulses (not under prefers-reduced-motion), carries a
    # static hazard marker (the non-motion cue) and switches its subtree to the crimson theme when the host enabled it.
    class ConditionBannerComponent < BaseComponent
      CONDITIONS = { normal: %i[status success check], caution: %i[status warning alert], critical: %i[alert emergency alert] }.freeze

      variant :condition, CONDITIONS.keys, default: :normal

      def self.block_name = "dp-condition-banner"

      def initialize(condition: nil, label: nil, **html_options)
        super(**html_options)
        assign_variants(condition:)
        raise ArgumentError, "label must not be empty (the condition needs a text)" if !label.nil? && label.to_s.strip.empty?

        @label = label
      end

      private

      def critical? = variants[:condition] == :critical
      def role = CONDITIONS.fetch(variants[:condition])[0]
      def color = CONDITIONS.fetch(variants[:condition])[1]
      def icon = CONDITIONS.fetch(variants[:condition])[2]
      def text = @label || t("deckplate.condition.#{variants[:condition]}")
      def theme = (critical? && Deckplate.configuration.themes.include?(:crimson) ? "crimson" : nil)

      def banner_attributes
        html_attributes(classes: [ block_name, *variant_classes, color_class(color) ], role: role, data: { dp_theme: theme }.compact)
      end
    end
  end
end
