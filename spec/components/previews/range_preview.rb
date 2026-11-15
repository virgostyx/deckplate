# @label Forms / Range
class RangePreview < ViewComponent::Preview
  def default
    render_with_template(template: "range_preview/default")
  end

  def states
    render_with_template(template: "range_preview/states")
  end
end
