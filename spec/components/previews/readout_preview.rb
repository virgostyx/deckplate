# @label Data / Readout
class ReadoutPreview < ViewComponent::Preview
  def default
    render_with_template(template: "readout_preview/default")
  end

  # Trends, missing value, colours, long numbers and a narrow container
  def states
    render_with_template(template: "readout_preview/states")
  end
end
