# @label Feedback / Spinner
class SpinnerPreview < ViewComponent::Preview
  def default
    render_with_template(template: "spinner_preview/default")
  end

  def variants
    render_with_template(template: "spinner_preview/variants")
  end
end
