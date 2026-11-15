# @label Navigation / Breadcrumb
class BreadcrumbPreview < ViewComponent::Preview
  def default
    render_with_template(template: "breadcrumb_preview/default")
  end

  # Wrapping on a narrow container
  def long
    render_with_template(template: "breadcrumb_preview/long")
  end
end
