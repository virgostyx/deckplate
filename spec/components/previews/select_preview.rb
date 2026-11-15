# @label Forms / Select
class SelectPreview < ViewComponent::Preview
  def default
    render_with_template(template: "select_preview/default")
  end

  # Blank option, groups, selected value, invalid, disabled
  def states
    render_with_template(template: "select_preview/states")
  end
end
