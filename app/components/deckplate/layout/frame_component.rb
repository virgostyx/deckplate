module Deckplate
  module Layout
    # Page frame: corner elbows, header bar, sidebar, main, aside, footer bar. Responsive through container queries
    # (the frame is a page-level layout: it fills the width of its parent). Below 48rem the sidebar becomes a native
    # popover opened by a "Menu" button (no JavaScript) and the corners are dropped.
    # Variants: :classic (sidebar left), :double (sidebar + aside), :minimal (header, main, footer only).
    # `animate: true` plays a short entrance cascade (header bar reveal, sidebar slide, content fade); off under prefers-reduced-motion.
    class FrameComponent < BaseComponent
      variant :variant, %i[classic double minimal], default: :classic

      renders_one :header, ->(&block) { tag.header(class: "dp-frame__header", &block) }
      renders_one :sidebar
      renders_one :aside, ->(&block) { tag.aside(class: "dp-frame__aside", &block) }
      renders_one :footer, ->(&block) { tag.footer(class: "dp-frame__footer", &block) }
      renders_one :top_left_corner, ->(&block) { tag.div(class: "dp-frame__corner dp-frame__corner--top-start", &block) }
      renders_one :bottom_left_corner, ->(&block) { tag.div(class: "dp-frame__corner dp-frame__corner--bottom-start", &block) }
      renders_one :main

      def initialize(variant: nil, theme: nil, fixed: false, animate: false, **html_options)
        super(**html_options)
        assign_variants(variant:)
        @fixed = fixed
        @animate = animate
        @theme = theme && validated_theme(theme)
      end

      private

      def minimal? = variants[:variant] == :minimal
      def double? = variants[:variant] == :double
      def base_id = @html_options[:id].presence || "dp-frame"
      def sidebar_id = "#{base_id}-sidebar"
      def main_id = "#{base_id}-main"
      def show_sidebar? = sidebar? && !minimal?
      def show_corners? = !minimal?

      def frame_attributes
        html_attributes(classes: [ block_name, *variant_classes, ("dp-frame--fixed" if @fixed), ("dp-frame--animate" if @animate) ],
                        data: ({ dp_theme: @theme.to_s } if @theme) || {})
      end

      def validated_theme(theme)
        return theme.to_sym if Deckplate.configuration.themes.include?(theme.to_sym)

        raise ArgumentError, "theme #{theme.inspect} is not enabled (themes: #{Deckplate.configuration.themes.join(', ')})"
      end
    end
  end
end
