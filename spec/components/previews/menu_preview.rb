# @label Navigation / Menu
class MenuPreview < ViewComponent::Preview
  # Click, or press ArrowDown/ArrowUp on the trigger; Escape closes and returns focus
  def default
    render_with_template(template: "menu_preview/default")
  end

  # Near the right edge of a narrow container (the popover is kept on screen)
  def edge
    render_with_template(template: "menu_preview/edge")
  end
end
