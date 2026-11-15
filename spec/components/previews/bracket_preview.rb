# @label Shapes / Bracket
class BracketPreview < ViewComponent::Preview
  # Start and end sides (the default)
  def default
    render_with_template(template: "bracket_preview/default")
  end

  # Every combination of sides
  def sides
    render_with_template(template: "bracket_preview/sides")
  end
end
