# @label Theme comparison
class ThemeComparisonPreview < ViewComponent::Preview
  # The same sample rendered in every enabled theme, side by side.
  def default
    render_with_template(template: "theme_comparison_preview/default", locals: {
      themes: Deckplate.configuration.themes,
      roles: Deckplate::Concerns::Colorable::ROLES
    })
  end
end
