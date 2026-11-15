# @label Controls / Toggle
class TogglePreview < ViewComponent::Preview
  # A switch (native checkbox, no JavaScript)
  def default
    render_with_template(template: "toggle_preview/default")
  end

  # Checked, disabled, colours, hidden unchecked value, long label
  def states
    render_with_template(template: "toggle_preview/states")
  end
end
