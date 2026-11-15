# @label Forms / FileInput
class FileInputPreview < ViewComponent::Preview
  def default
    render_with_template(template: "file_input_preview/default")
  end

  def states
    render_with_template(template: "file_input_preview/states")
  end
end
