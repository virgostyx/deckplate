# @label Layout / Frame
class FramePreview < ViewComponent::Preview
  # Classic: corners, header bar, sidebar on the left. Narrow the window below 48rem: the sidebar becomes a "Menu" popover.
  def classic
    render_with_template(template: "frame_preview/show", locals: { variant: :classic, fixed: false })
  end

  # Sidebar and aside
  def double
    render_with_template(template: "frame_preview/show", locals: { variant: :double, fixed: false })
  end

  # Header, main and footer only
  def minimal
    render_with_template(template: "frame_preview/show", locals: { variant: :minimal, fixed: false })
  end

  # Fills the viewport; only the main area scrolls
  def fixed
    render_with_template(template: "frame_preview/show", locals: { variant: :classic, fixed: true })
  end
end
