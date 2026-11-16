# @label Feedback / Toast
class ToastPreview < ViewComponent::Preview
  # Static toasts (duration 0 so they stay). In an app they are appended to #dp-toasts by a Turbo Stream, see the guide.
  def default
    render_with_template(template: "toast_preview/default")
  end

  def kinds
    render_with_template(template: "toast_preview/kinds")
  end
end
