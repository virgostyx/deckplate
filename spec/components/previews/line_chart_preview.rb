# @label Data / LineChart
class LineChartPreview < ViewComponent::Preview
  def default
    render_with_template(template: "line_chart_preview/default")
  end

  # Several series, filled areas, a threshold, negative values and a long axis
  def variants
    render_with_template(template: "line_chart_preview/variants")
  end
end
