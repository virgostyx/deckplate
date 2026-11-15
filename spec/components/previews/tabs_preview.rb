# @label Navigation / Tabs
class TabsPreview < ViewComponent::Preview
  # Arrow keys, Home and End move between tabs; the Tab key goes to the panel
  def default
    render_with_template(template: "tabs_preview/default", locals: { selected: nil, hash: false })
  end

  # Second tab selected on the server
  def selected
    render_with_template(template: "tabs_preview/default", locals: { selected: "crew", hash: false })
  end

  # The selected tab follows the URL hash (#cargo)
  def with_hash
    render_with_template(template: "tabs_preview/default", locals: { selected: nil, hash: true })
  end

  # Many tabs with long labels wrap onto several lines
  def many
    render_with_template(template: "tabs_preview/many")
  end
end
