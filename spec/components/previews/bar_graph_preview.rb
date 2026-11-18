# @label Data / BarGraph
class BarGraphPreview < ViewComponent::Preview
  def default
    render_with_template(template: "bar_graph_preview/default")
  end

  def variants
    render_with_template(template: "bar_graph_preview/variants")
  end

  # Several values per item: grouped side by side, or stacked into one bar; horizontal and vertical
  def multiple
    render_with_template(template: "bar_graph_preview/multiple")
  end
end
