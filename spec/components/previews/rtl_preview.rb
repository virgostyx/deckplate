# @label Shapes / Right-to-left
class RtlPreview < ViewComponent::Preview
  # Text-free shapes. Open with ?dir=rtl: the picture must be the LTR one flipped horizontally (checked pixel by pixel, ADR 0017)
  def shapes
    render_with_template(template: "rtl_preview/shapes")
  end
end
