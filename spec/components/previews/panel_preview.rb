# @label Layout / Panel
class PanelPreview < ViewComponent::Preview
  # Plain bars (corners: :none)
  def default
    render_with_template(template: "panel_preview/default")
  end

  # Elbow corners on the left, and on both sides
  def corners
    render_with_template(template: "panel_preview/corners")
  end

  # Header actions, footer, long content, empty body, narrow container
  def edge_cases
    render_with_template(template: "panel_preview/edge_cases")
  end

  # A realistic composition: panels in a dashboard grid
  def composition
    render_with_template(template: "panel_preview/composition")
  end
end
