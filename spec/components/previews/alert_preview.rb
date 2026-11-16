# @label Feedback / Alert
class AlertPreview < ViewComponent::Preview
  def default
    render_with_template(template: "alert_preview/default")
  end

  # Every kind, a title, dismissible (the close button removes it and moves the focus on), long unbreakable content
  def kinds
    render_with_template(template: "alert_preview/kinds")
  end
end
