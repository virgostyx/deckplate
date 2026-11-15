# @label Controls / ButtonGroup
class ButtonGroupPreview < ViewComponent::Preview
  def default
    render_with_template(template: "button_group_preview/default")
  end

  # Vertical stack, as used in sidebars
  def vertical
    render_with_template(template: "button_group_preview/vertical")
  end
end
