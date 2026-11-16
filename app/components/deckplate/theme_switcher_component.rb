module Deckplate
  # Theme choice as toggle buttons (aria-pressed). dp-theme sets data-dp-theme on <html> and writes the `dp_theme` cookie, which
  # `dp_theme_attrs` reads on the server: the first paint after a reload is already in the right theme (no flash).
  class ThemeSwitcherComponent < BaseComponent
    def self.block_name = "dp-theme-switcher"

    def initialize(label: nil, **html_options)
      super(**html_options)
      @label = label
    end

    private

    def themes = Deckplate.configuration.themes
    def current = helpers.dp_theme_attrs.dig(:data, :dp_theme)
    def title(theme) = t("deckplate.theme.names.#{theme}", default: theme.to_s.tr("-", " ").capitalize)

    def switcher_attributes
      html_attributes(
        classes: [ block_name ], role: "group", aria: { label: @label.presence || t("deckplate.theme.label") },
        data: { controller: "dp-theme", action: "turbo:before-morph-attribute->dp-theme#keepState",
                dp_theme_themes_value: themes.map(&:to_s).to_json, dp_theme_cookie_value: Helpers::THEME_COOKIE }
      )
    end
  end
end
