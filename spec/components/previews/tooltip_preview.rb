# @label Feedback / Tooltip
class TooltipPreview < ViewComponent::Preview
  # Hover or focus the button; Escape dismisses the tooltip
  def default
    render_with_template(template: "tooltip_preview/default")
  end

  # Four placements, a bubble that flips because it sits at the top edge, and a 500 ms hover delay
  def placements
    render_with_template(template: "tooltip_preview/placements")
  end
end
