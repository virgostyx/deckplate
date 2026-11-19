module Deckplate
  module Data
    # A list the user can put in order: a pointer drag on the grip, or the move up / move down buttons that exist for every item (keyboard,
    # touch, screen readers: no drag is ever required, WCAG 2.5.7). The order is kept in the DOM, announced politely, sent to the page as a
    # `dp-sortable:reorder` event ({ ids }) and, with name:, submitted with a form as one hidden field per item (dp-sortable).
    class SortableListComponent < BaseComponent
      def self.block_name = "dp-sortable"

      # items: [[id, text], ...], a Hash { id => text } or plain strings (id = text). Ids are unique.
      def initialize(label:, items:, name: nil, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (it names the list)" if label.to_s.strip.empty?
        raise ArgumentError, "items must not be empty" if items.blank?

        @label = label
        @name = name
        @items = items.to_a.map { |entry| normalize(entry) }
        ids = @items.map(&:first)
        raise ArgumentError, "item ids must be unique (duplicate: #{ids.tally.find { _2 > 1 }.first.inspect})" if ids.uniq.size != ids.size
      end

      private

      def normalize(entry)
        id, text = entry.is_a?(Array) ? entry : [ entry, entry ]
        raise ArgumentError, "an item needs an id (got #{entry.inspect})" if id.to_s.strip.empty?
        raise ArgumentError, "an item needs a text (got #{entry.inspect})" if text.to_s.strip.empty?

        [ id.to_s, text.to_s ]
      end

      def wrapper_attributes
        html_attributes(classes: [ block_name ], data: { controller: "dp-sortable", action: "pointermove->dp-sortable#drag pointerup->dp-sortable#drop pointercancel->dp-sortable#drop", dp_sortable_moved_template_value: t("deckplate.sortable.moved", item: "%{item}", position: "%{position}", total: "%{total}") })
      end

      def move_button(text, direction, icon)
        key = direction.negative? ? "move_up" : "move_down"
        tag.button(helpers.dp_icon(icon), type: "button", class: "dp-sortable__move", aria: { label: t("deckplate.sortable.#{key}", item: text) },
                   data: { action: "dp-sortable#move", dp_sortable_direction_param: direction })
      end
    end
  end
end
