# @label Forms / DateInput
class DateInputPreview < ViewComponent::Preview
  def default
    render_with_template(template: "date_input_preview/default")
  end

  # Every native type, plus an invalid and a disabled field
  def states
    render_with_template(template: "date_input_preview/states")
  end
end
