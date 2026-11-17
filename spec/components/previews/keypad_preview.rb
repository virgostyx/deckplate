# @label Forms / Keypad
class KeypadPreview < ViewComponent::Preview
  # A four-digit code in a real form (GET /up?pin=...): the pad fills the input, the physical keyboard works too, Enter submits
  def default
    render_with_template(template: "keypad_preview/default")
  end

  # Masked code, free length, preset value, error, disabled
  def states
    render_with_template(template: "keypad_preview/states")
  end
end
