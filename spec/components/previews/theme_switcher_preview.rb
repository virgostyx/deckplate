# @label Controls / ThemeSwitcher
class ThemeSwitcherPreview < ViewComponent::Preview
  # Toggle buttons (aria-pressed); the choice is stored in the dp_theme cookie, which the server reads for the first paint
  def default
    render_with_template(template: "theme_switcher_preview/default")
  end
end
