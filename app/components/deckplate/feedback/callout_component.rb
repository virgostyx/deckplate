module Deckplate
  module Feedback
    # A highlighted note inside running content.
    class CalloutComponent < BaseComponent
      KINDS = { note: %i[accent info], tip: %i[info check], warning: %i[warning alert] }.freeze

      variant :kind, KINDS.keys, default: :note

      def self.block_name = "dp-callout"

      def initialize(kind: nil, title: nil, **html_options)
        super(**html_options)
        assign_variants(kind:)
        @title = title
      end

      private

      def color = KINDS.fetch(variants[:kind])[0]
      def icon = KINDS.fetch(variants[:kind])[1]
      def heading = @title.presence || t("deckplate.callout.#{variants[:kind]}")
      def callout_attributes = html_attributes(classes: [ block_name, *variant_classes, color_class(color) ], role: "note")
    end
  end
end
