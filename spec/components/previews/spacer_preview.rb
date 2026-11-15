# @label Shapes / Spacer
class SpacerPreview < ViewComponent::Preview
  # A transparent gap in layout units. The coloured bars below only visualise the gap.
  def default
    render_with_template(template: "spacer_preview/default")
  end

  # Block and inline axes, fractional sizes
  def sizes
    render_with_template(template: "spacer_preview/sizes")
  end
end
