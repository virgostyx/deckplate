module Deckplate
  module Forms
    # Row for the submit / cancel controls of a form.
    class FormActionsComponent < BaseComponent
      variant :align, %i[start end], default: :start

      def initialize(align: nil, **html_options)
        super(**html_options)
        assign_variants(align:)
      end

      def self.block_name = "dp-form-actions"
    end
  end
end
