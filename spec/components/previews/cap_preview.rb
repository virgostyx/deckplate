# @label Shapes / Cap
class CapPreview < ViewComponent::Preview
  # Half-pill end piece
  def default
    render_with_template(template: "cap_preview/default")
  end

  # Both sides in every semantic role
  def variants
    render_with_template(template: "cap_preview/variants", locals: { roles: Deckplate::Concerns::Colorable::ROLES })
  end
end
