# @label Data / SortableList
class SortableListPreview < ViewComponent::Preview
  # Drag the grip, or use the up and down buttons (they work with the keyboard, touch and screen readers)
  def default
    render_with_template(template: "sortable_list_preview/default")
  end
end
