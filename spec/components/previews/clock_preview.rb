# @label Data / Clock
class ClockPreview < ViewComponent::Preview
  # Ticks every second from the server's time (pass a fixed time to get stable output)
  def default
    render_with_template(template: "clock_preview/default")
  end

  def formats
    render_with_template(template: "clock_preview/formats")
  end
end
