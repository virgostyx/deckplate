module ApplicationHelper
  # Lookbook sends the toolbar choices as a JSON string: _display={"theme":"azure"}
  def preview_theme
    display = params[:_display]
    display = JSON.parse(display) if display.is_a?(String)
    theme = display.to_h.with_indifferent_access[:theme].to_s
    Deckplate.configuration.themes.map(&:to_s).include?(theme) ? theme : dp_theme_attrs.dig(:data, :dp_theme)
  rescue JSON::ParserError
    dp_theme_attrs.dig(:data, :dp_theme)
  end
end
