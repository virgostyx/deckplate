# @label Forms / RadioGroup
class RadioGroupPreview < ViewComponent::Preview
  def default
    render_with_template(template: "radio_group_preview/default")
  end

  def states
    render_with_template(template: "radio_group_preview/states")
  end
end
