# @label Feedback / Modal
class ModalPreview < ViewComponent::Preview
  # A confirmation dialog, closed. Open it with the button.
  def default
    render_with_template(template: "modal_preview/default")
  end

  # Already open (for the visual baselines)
  def open
    render_with_template(template: "modal_preview/open")
  end

  # A form in a modal: closes after a successful Turbo submission, stays open on a 422
  def form
    render_with_template(template: "modal_preview/form")
  end

  # Sizes and long scrolling content
  def long
    render_with_template(template: "modal_preview/long")
  end
end
