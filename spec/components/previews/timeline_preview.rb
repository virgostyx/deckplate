# @label Data / Timeline
class TimelinePreview < ViewComponent::Preview
  # Done, current and upcoming events (the state is an icon or shape and a hidden text, never colour alone)
  def default
    render_with_template(template: "timeline_preview/default")
  end

  # One event, no times, a long title and body, per-event colours, many events
  def edge_cases
    render_with_template(template: "timeline_preview/edge_cases")
  end

  # A timeline inside a panel next to a readout
  def composition
    render_with_template(template: "timeline_preview/composition")
  end
end
