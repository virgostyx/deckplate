module Deckplate
  module Concerns
    # Shared by form controls: the ids that tie a control to its hint and its errors (FormField renders the targets).
    # Ids are derived from the control id, so rendering stays deterministic.
    module Describable
      private

      # Rails-style names become ids: ship[first_name] -> ship_first_name
      def derive_id(name)
        name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").delete_suffix("_")
      end

      def normalize_errors(errors)
        Array(errors).map(&:to_s).reject { |e| e.strip.empty? }
      end

      def invalid? = @errors.present?
      def hint_id = ("#{@field_id}-hint" if @hint.present?)
      def error_id = ("#{@field_id}-error" if invalid?)
      def describedby_ids = [ hint_id, error_id ].compact.join(" ").presence
    end
  end
end
