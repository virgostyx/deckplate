# @label Feedback / EmptyState
class EmptyStatePreview < ViewComponent::Preview
  def default
    render_with_template(template: "empty_state_preview/default")
  end

  def variants
    render_with_template(template: "empty_state_preview/variants")
  end
end
