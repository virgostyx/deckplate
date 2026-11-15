# @label Navigation / Nav
class NavPreview < ViewComponent::Preview
  # Sidebar navigation. The link of the current page (here /ships) carries aria-current and a non-colour marker.
  def default
    render_with_template(template: "nav_preview/default")
  end

  # Colours, no numbers, a long label
  def variants
    render_with_template(template: "nav_preview/variants")
  end
end
