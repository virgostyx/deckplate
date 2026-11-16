# @label Feedback / ConditionBanner
class ConditionBannerPreview < ViewComponent::Preview
  def default
    render_with_template(template: "condition_banner_preview/default")
  end

  # The three conditions (critical pulses, but never under prefers-reduced-motion, and has a static hazard marker)
  def conditions
    render_with_template(template: "condition_banner_preview/conditions")
  end
end
