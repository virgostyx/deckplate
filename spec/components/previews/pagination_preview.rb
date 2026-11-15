# @label Navigation / Pagination
class PaginationPreview < ViewComponent::Preview
  def default
    render_with_template(template: "pagination_preview/default", locals: { page: 3, pages: 5 })
  end

  # First, middle and last page of a long list
  def long
    render_with_template(template: "pagination_preview/long")
  end
end
