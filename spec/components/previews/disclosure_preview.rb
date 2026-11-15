# @label Navigation / Disclosure
class DisclosurePreview < ViewComponent::Preview
  def default
    render_with_template(template: "disclosure_preview/default")
  end

  # Open, colours, long summary and content
  def variants
    render_with_template(template: "disclosure_preview/variants")
  end
end
