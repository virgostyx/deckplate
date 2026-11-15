# @label Reference / Classic console
class ClassicConsolePreview < ViewComponent::Preview
  # Reproduces the proportions of a classic bridge-console page (column width, bar thickness, gaps, radii)
  # using only Deckplate components. Used to tune the geometry tokens (SPEC 5.4).
  def default
    render_with_template(template: "classic_console_preview/default")
  end
end
