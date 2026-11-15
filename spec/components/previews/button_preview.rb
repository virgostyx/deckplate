# @label Controls / Button
class ButtonPreview < ViewComponent::Preview
  # A pill button
  def default
    render_with_template(template: "button_preview/default")
  end

  # Shapes, sizes and colours
  def variants
    render_with_template(template: "button_preview/variants", locals: { roles: Deckplate::Concerns::Colorable::ROLES })
  end

  # Disabled, loading, link, disabled link, icon, button_to (delete), long label
  def states
    render_with_template(template: "button_preview/states")
  end
end
