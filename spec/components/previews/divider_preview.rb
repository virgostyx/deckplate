# @label Shapes / Divider
class DividerPreview < ViewComponent::Preview
  # A solid rule
  def default
    render_with_template(template: "divider_preview/default")
  end

  # Segment counts, per-segment colours, and a narrow container
  def segmented
    render_with_template(template: "divider_preview/segmented")
  end
end
