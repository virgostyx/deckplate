# @label Data / Gauge
class GaugePreview < ViewComponent::Preview
  def default
    render_with_template(template: "gauge_preview/default")
  end

  # Radial and semicircle, extremes, units, colours
  def variants
    render_with_template(template: "gauge_preview/variants")
  end
end
