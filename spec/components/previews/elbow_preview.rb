# @label Shapes / Elbow
class ElbowPreview < ViewComponent::Preview
  # The signature shape. The inner arc is a real cut-out: the background shows through.
  def default
    render_with_template(template: "elbow_preview/default")
  end

  # All four corners, three sizes, custom dimensions
  def variants
    render_with_template(template: "elbow_preview/variants")
  end

  # Labels, in every corner (long label is clipped)
  def labels
    render_with_template(template: "elbow_preview/labels")
  end

  # Transparency proof over a patterned background, with a grid overlay and computed sizes
  def geometry
    render_with_template(template: "elbow_preview/geometry")
  end
end
