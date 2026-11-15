module Deckplate
  module Layout
    class PageHeaderComponent < BaseComponent
      include Concerns::Headed

      renders_one :breadcrumb, ->(&block) { tag.div(class: "dp-page-header__breadcrumb", &block) }
      renders_one :actions, ->(&block) { tag.div(class: "dp-page-header__actions", &block) }

      def initialize(title:, subtitle: nil, level: 1, **html_options)
        super(**html_options)
        @title = validate_title!(title)
        @subtitle = subtitle
        @level = validate_level!(level)
      end
    end
  end
end
