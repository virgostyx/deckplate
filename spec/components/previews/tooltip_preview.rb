# @label Feedback / Tooltip
class TooltipPreview < ViewComponent::Preview
  # Hover or focus the button; Escape dismisses the tooltip
  def default
    render_with_template(template: "tooltip_preview/default")
  end
end
