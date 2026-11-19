# @label Data / Donut
class DonutPreview < ViewComponent::Preview
  def default
    render_with_template(template: "donut_preview/default")
  end

  # A custom centre, zero values, a single slice and many slices (the colours repeat after eight)
  def variants
    render_with_template(template: "donut_preview/variants")
  end
end
