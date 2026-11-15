# @label Layout / PageHeader
class PageHeaderPreview < ViewComponent::Preview
  # Title only
  def default
    render_with_template(template: "page_header_preview/default")
  end

  # Subtitle, breadcrumb, actions; and a long title that must wrap, not overflow
  def full
    render_with_template(template: "page_header_preview/full")
  end
end
