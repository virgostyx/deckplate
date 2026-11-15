# @label Data / Sparkline
class SparklinePreview < ViewComponent::Preview
  def default
    render_with_template(template: "sparkline_preview/default")
  end

  def variants
    render_with_template(template: "sparkline_preview/variants")
  end
end
