module Deckplate
  # View helpers, included in every ActionView (see Deckplate::Engine).
  module Helpers
    PRELOADED_FONTS = %w[antonio-latin share-tech-mono-latin].freeze
    THEME_COOKIE = "dp_theme".freeze

    # 24x24 stroke icons (currentColor, 2px round). Original artwork.
    ICONS = {
      close: [ "M6 6l12 12M18 6L6 18" ],
      chevron_left: [ "M15 5l-7 7 7 7" ],
      chevron_right: [ "M9 5l7 7-7 7" ],
      chevron_up: [ "M5 15l7-7 7 7" ],
      chevron_down: [ "M5 9l7 7 7-7" ],
      check: [ "M5 12.5l4.5 4.5L19 7" ],
      alert: [ "M12 3L2.5 20h19L12 3z", "M12 10v5M12 17.5v.5" ],
      info: [ "M12 21a9 9 0 100-18 9 9 0 000 18z", "M12 11v6M12 7.5v.5" ],
      menu: [ "M4 6h16M4 12h16M4 18h16" ],
      search: [ "M10.5 18a7.5 7.5 0 100-15 7.5 7.5 0 000 15z", "M16 16l5 5" ],
      plus: [ "M12 5v14M5 12h14" ],
      minus: [ "M5 12h14" ],
      sort_asc: [ "M12 19V5M6 11l6-6 6 6" ],
      sort_desc: [ "M12 5v14M6 13l6 6 6-6" ],
      external: [ "M14 4h6v6M20 4l-9 9", "M18 14v5a1 1 0 01-1 1H5a1 1 0 01-1-1V7a1 1 0 011-1h5" ]
    }.freeze

    # Icons that point a direction: mirrored in right-to-left text (ADR 0017)
    DIRECTIONAL_ICONS = %i[chevron_left chevron_right].freeze

    # <link rel="preload"> tags for the two latin fonts. Put it in <head>, before the stylesheet.
    def dp_font_tags
      safe_join(PRELOADED_FONTS.map do |name|
        tag.link(rel: "preload", href: asset_path("deckplate/#{name}.woff2"), as: "font", type: "font/woff2", crossorigin: "anonymous")
      end, "\n")
    end

    # Attributes for <html>/<body>: <html <%= tag.attributes(dp_theme_attrs) %>>
    # The theme comes from the dp_theme cookie when it names an enabled theme, so the first paint is right.
    def dp_theme_attrs
      { data: { dp_theme: dp_current_theme.to_s } }
    end

    # Sound is opt-in (config.sounds): without it this is empty and no controller is attached. The controller listens for `dp:sound`
    # window events and for the click tone of buttons; it creates no AudioContext before a user gesture.
    def dp_sound_attrs
      return {} unless Deckplate.configuration.sounds

      { data: { controller: "dp-sound", action: "dp:sound@window->dp-sound#fromEvent turbo:before-morph-attribute->dp-sound#keepState" } }
    end

    # <div class="dp-root">: canvas colour, fonts and focus ring apply inside it only.
    def dp_root(tag: :div, theme: nil, **options, &block)
      options[:class] = [ "dp-root", *Array(options[:class]) ]
      options[:data] = (options[:data] || {}).merge(dp_theme: dp_validated_theme(theme).to_s) if theme
      sound = dp_sound_attrs[:data]
      options[:data] = (options[:data] || {}).merge(sound) if sound
      content_tag(tag, capture(&block), **options)
    end

    # The Turbo Stream target for toasts: <%= dp_toast_container %> once in the layout, then
    # turbo_stream.append "dp-toasts", Deckplate::Feedback::ToastComponent.new(...). A polite live region that announces additions.
    # Flash messages can be rendered inside it (block). `max:` caps the stack (oldest removed). `permanent: true` keeps the container
    # and its toasts across Turbo morphs, at the price that toasts rendered by the next page are ignored (see the feedback guide).
    def dp_toast_container(max: 5, permanent: false, &block)
      raise ArgumentError, "max must be an Integer >= 1, got #{max.inspect}" unless max.is_a?(Integer) && max >= 1

      content_tag(:div, (capture(&block) if block), id: "dp-toasts", class: "dp-toast-container", role: "region",
                  aria: { live: "polite", relevant: "additions", atomic: "false", label: t("deckplate.feedback.notifications") },
                  data: { dp_toast_max: max, turbo_permanent: (true if permanent) }.compact)
    end

    def dp_color_class(color)
      Concerns::Colorable.css_class(Concerns::Colorable.resolve(color))
    end

    def dp_icon(name, title: nil, **options)
      paths = ICONS.fetch(name.to_sym) do
        raise ArgumentError, "unknown icon #{name.inspect}; valid: #{ICONS.keys.map(&:inspect).join(', ')}"
      end
      options[:class] = [ "dp-icon", ("dp-icon--directional" if DIRECTIONAL_ICONS.include?(name.to_sym)), *Array(options[:class]) ].compact
      options.merge!(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
                     "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round", focusable: "false")
      if title
        options.merge!(role: "img")
      else
        options["aria-hidden"] = "true"
      end
      content_tag(:svg, options) do
        safe_join([ (content_tag(:title, title) if title), *paths.map { |d| tag.path(d:) } ].compact)
      end
    end

    private

    def dp_current_theme
      cookie = request&.cookies&.[](THEME_COOKIE)
      allowed = Deckplate.configuration.themes.map(&:to_s)
      allowed.include?(cookie) ? cookie.to_sym : Deckplate.configuration.default_theme
    end

    def dp_validated_theme(theme)
      return theme.to_sym if Deckplate.configuration.themes.include?(theme.to_sym)

      raise ArgumentError, "theme #{theme.inspect} is not enabled (themes: #{Deckplate.configuration.themes.join(', ')})"
    end
  end
end
