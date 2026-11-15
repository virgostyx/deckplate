# @label Data / BarGraph
class BarGraphPreview < ViewComponent::Preview
  def default
    render_with_template(template: "bar_graph_preview/default")
  end

  def variants
    render_with_template(template: "bar_graph_preview/variants")
  end
end
