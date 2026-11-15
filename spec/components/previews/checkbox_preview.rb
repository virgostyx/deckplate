# @label Forms / Checkbox
class CheckboxPreview < ViewComponent::Preview
  def default
    render_with_template(template: "checkbox_preview/default")
  end

  def states
    render_with_template(template: "checkbox_preview/states")
  end
end
