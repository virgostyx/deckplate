# @label Data / Table
class TablePreview < ViewComponent::Preview
  ROWS = [ [ "Hull", 12.5, "ok" ], [ "Core", 98.25, "warn" ], [ "Deck 7", 3, "ok" ], [ "Shields", 100, "fail" ] ].freeze

  def default
    render_with_template(template: "table_preview/default", locals: { rows: ROWS })
  end

  # The host sorts: here by value, descending. Header links and aria-sort come from the component.
  def sorted
    render_with_template(template: "table_preview/sorted", locals: { rows: ROWS.sort_by { |r| -r[1] } })
  end

  # Footer (totals), zebra rows, hidden caption
  def footer
    render_with_template(template: "table_preview/footer", locals: { rows: ROWS })
  end

  def empty
    render_with_template(template: "table_preview/empty")
  end

  # Sticky header in a short scrolling area, and a wide table inside a narrow container
  def scrolling
    render_with_template(template: "table_preview/scrolling")
  end
end
