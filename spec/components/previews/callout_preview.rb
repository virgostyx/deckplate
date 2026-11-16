# @label Feedback / Callout
class CalloutPreview < ViewComponent::Preview
  def default
    render_with_template(template: "callout_preview/default")
  end

  def kinds
    render_with_template(template: "callout_preview/kinds")
  end
end
