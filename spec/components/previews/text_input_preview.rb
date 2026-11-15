# @label Forms / TextInput
class TextInputPreview < ViewComponent::Preview
  def default
    render_with_template(template: "text_input_preview/default")
  end

  # Types, then hint / required / invalid / disabled / read-only, and an overlong label and error
  def states
    render_with_template(template: "text_input_preview/states")
  end
end
