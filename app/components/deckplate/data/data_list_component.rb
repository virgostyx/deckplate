module Deckplate
  module Data
    # Key/value panel as a <dl>. items: [["Class", "Explorer"]] or { "Class" => "Explorer" }, and/or `with_item(label:) { rich content }`.
    class DataListComponent < BaseComponent
      renders_many :items, ->(label:, &block) {
        safe_join([ tag.dt(label, class: "dp-data-list__term"), tag.dd(class: "dp-data-list__detail", &block) ])
      }

      def self.block_name = "dp-data-list"

      def initialize(items: [], color: :secondary, **html_options)
        super(**html_options)
        @pairs = items.to_a.map { |item| normalize(item) }
        @color = resolve_color(color)
      end

      private

      def normalize(item)
        raise ArgumentError, "invalid item #{item.inspect}: use [label, value]" unless item.is_a?(Array) && item.size == 2
        raise ArgumentError, "an item needs a label (got #{item.inspect})" if item.first.to_s.strip.empty?

        item
      end

      def list_attributes = html_attributes(classes: [ block_name, color_class(@color) ])
    end
  end
end
