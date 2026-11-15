# @label Forms / FormActions
class FormActionsPreview < ViewComponent::Preview
  def default
    render_with_template(template: "form_actions_preview/default")
  end

  # Aligned to the end, and wrapping in a narrow container
  def aligned
    render_with_template(template: "form_actions_preview/aligned")
  end
end
