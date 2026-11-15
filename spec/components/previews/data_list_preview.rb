# @label Data / DataList
class DataListPreview < ViewComponent::Preview
  def default
    render_with_template(template: "data_list_preview/default")
  end

  # Rich values through slots, long values that wrap
  def rich
    render_with_template(template: "data_list_preview/rich")
  end
end
