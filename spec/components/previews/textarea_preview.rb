# @label Forms / Textarea
class TextareaPreview < ViewComponent::Preview
  def default
    render_with_template(template: "textarea_preview/default")
  end

  def states
    render_with_template(template: "textarea_preview/states")
  end
end
