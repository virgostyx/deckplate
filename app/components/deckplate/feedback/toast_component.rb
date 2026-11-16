module Deckplate
  module Feedback
    # Transient message, appended into the #dp-toasts container (dp_toast_container) by a Turbo Stream or rendered from the flash.
    # info/success dismiss themselves after `duration` ms (default 5000); warning/danger stay until dismissed (0): they must be readable.
    # The timer pauses on hover and focus (dp-toast).
    class ToastComponent < BaseComponent
      KINDS = AlertComponent::KINDS
      DEFAULT_DURATION = { info: 5000, success: 5000, warning: 0, danger: 0 }.freeze

      variant :kind, KINDS.keys, default: :info

      def self.block_name = "dp-toast"

      def initialize(kind: nil, duration: nil, **html_options)
        super(**html_options)
        assign_variants(kind:)
        raise ArgumentError, "duration must be an Integer number of milliseconds >= 0 (0 keeps the toast), got #{duration.inspect}" unless duration.nil? || (duration.is_a?(Integer) && duration >= 0)

        @duration = duration || DEFAULT_DURATION.fetch(variants[:kind])
      end

      private

      def role = KINDS.fetch(variants[:kind])[0]
      def color = KINDS.fetch(variants[:kind])[1]
      def icon = KINDS.fetch(variants[:kind])[2]

      TONES = { info: "confirm", success: "confirm", warning: "alert", danger: "error" }.freeze

      def tone = (TONES.fetch(variants[:kind]) if Deckplate.configuration.sounds)

      def toast_attributes
        html_attributes(classes: [ block_name, *variant_classes, color_class(color) ], role: role,
                        data: { controller: "dp-toast", dp_toast_duration_value: @duration, dp_toast_tone_value: tone,
                                action: "mouseenter->dp-toast#pause mouseleave->dp-toast#resume focusin->dp-toast#pause focusout->dp-toast#resume" })
      end
    end
  end
end
