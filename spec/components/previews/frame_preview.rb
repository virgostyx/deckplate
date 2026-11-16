# @label Layout / Frame
class FramePreview < ViewComponent::Preview
  # Classic: corners, header bar, sidebar on the left. Narrow the window below 48rem: the sidebar becomes a "Menu" popover.
  def classic
    render_with_template(template: "frame_preview/show", locals: { variant: :classic, fixed: false, animate: false })
  end

  # Sidebar and aside
  def double
    render_with_template(template: "frame_preview/show", locals: { variant: :double, fixed: false, animate: false })
  end

  # Header, main and footer only
  def minimal
    render_with_template(template: "frame_preview/show", locals: { variant: :minimal, fixed: false, animate: false })
  end

  # The entrance cascade: header bar reveal, sidebar slide, content fade (off under prefers-reduced-motion)
  def animated
    render_with_template(template: "frame_preview/show", locals: { variant: :classic, fixed: false, animate: true })
  end

  # Fills the viewport; only the main area scrolls
  def fixed
    render_with_template(template: "frame_preview/show", locals: { variant: :classic, fixed: true, animate: false })
  end
end
