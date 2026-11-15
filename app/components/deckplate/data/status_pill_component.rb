module Deckplate
  module Data
    # A status in a pill: text is always there, with a different icon per status and a colour role (never colour alone).
    class StatusPillComponent < BaseComponent
      STATUSES = { ok: %i[success check], warn: %i[warning alert], fail: %i[danger close], idle: %i[muted minus], info: %i[info info] }.freeze

      variant :status, STATUSES.keys, default: :ok

      def self.block_name = "dp-status-pill"

      def initialize(status:, label: nil, **html_options)
        super(**html_options)
        assign_variants(status:)
        raise ArgumentError, "label must not be empty (the status needs a text)" if !label.nil? && label.to_s.strip.empty?

        @label = label
      end

      private

      def role = STATUSES.fetch(variants[:status]).first
      def icon = STATUSES.fetch(variants[:status]).last
      def text = @label || t("deckplate.status.#{variants[:status]}")
      def pill_attributes = html_attributes(classes: [ block_name, *variant_classes, color_class(role) ])
    end
  end
end
