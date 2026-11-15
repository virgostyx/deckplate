# @label Data / Progress
class ProgressPreview < ViewComponent::Preview
  def default
    render_with_template(template: "progress_preview/default")
  end

  # Values, segmented, indeterminate, colours
  def variants
    render_with_template(template: "progress_preview/variants")
  end
end
