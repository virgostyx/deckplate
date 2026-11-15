# @label Shapes / Bar
class BarPreview < ViewComponent::Preview
  # A plain horizontal bar
  def default
    render_with_template(template: "bar_preview/default")
  end

  # Caps, thickness and colours
  def variants
    render_with_template(template: "bar_preview/variants", locals: { roles: Deckplate::Concerns::Colorable::ROLES })
  end

  # Title, and a bar made of coloured segments (some sized in units, the rest share what is left)
  def segments
    render_with_template(template: "bar_preview/segments")
  end

  # Fill inside a flex row, a long title that must not overflow, and vertical bars
  def layouts
    render_with_template(template: "bar_preview/layouts")
  end
end
