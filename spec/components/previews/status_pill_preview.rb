# @label Data / StatusPill
class StatusPillPreview < ViewComponent::Preview
  def default
    render_with_template(template: "status_pill_preview/default")
  end

  def all
    render_with_template(template: "status_pill_preview/all")
  end
end
