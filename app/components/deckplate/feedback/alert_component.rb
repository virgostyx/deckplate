module Deckplate
  module Feedback
    # Inline message. info/success are role="status" (polite), warning/danger role="alert" (assertive).
    # The kind is an icon and a word (for assistive technology) as well as a colour. `dismissible:` adds a close button (dp-dismiss).
    class AlertComponent < BaseComponent
      KINDS = { info: %i[status info info], success: %i[status success check], warning: %i[alert warning alert], danger: %i[alert danger close] }.freeze

      variant :kind, KINDS.keys, default: :info

      def self.block_name = "dp-alert"

      def initialize(kind: nil, title: nil, dismissible: false, **html_options)
        super(**html_options)
        assign_variants(kind:)
        @title = title
        @dismissible = dismissible
      end

      private

      def role = KINDS.fetch(variants[:kind])[0]
      def color = KINDS.fetch(variants[:kind])[1]
      def icon = KINDS.fetch(variants[:kind])[2]

      def alert_attributes
        html_attributes(classes: [ block_name, *variant_classes, color_class(color) ], role: role,
                        data: (@dismissible ? { controller: "dp-dismiss" } : {}))
      end
    end
  end
end
