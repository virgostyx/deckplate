# @label Layout / Section
class SectionPreview < ViewComponent::Preview
  # A titled section, named by its heading (id given)
  def default
    render_with_template(template: "section_preview/default")
  end

  # Colours and heading levels
  def variants
    render_with_template(template: "section_preview/variants")
  end
end
