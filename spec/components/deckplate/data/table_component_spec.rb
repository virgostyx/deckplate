require "spec_helper"

RSpec.describe Deckplate::Data::TableComponent, type: :component do
  Reading = Struct.new(:id, :name, :value, :status)

  let(:rows) { [ Reading.new(1, "Hull", 12.5, "ok"), Reading.new(2, "Core", 98.25, "warn"), Reading.new(3, "Deck <7>", 3, "ok") ] }
  let(:sort_url) { ->(key, dir) { "/readings?sort=#{key}&dir=#{dir}" } }

  def render_table(rows: self.rows, caption: "Sensor readings", **opts, &extra)
    render_inline(described_class.new(rows:, caption:, **opts)) do |t|
      t.with_column(:name, header: "Sensor", sortable: true, row_header: true) { |r| r.name }
      t.with_column(:value, header: "Value", sortable: true, align: :end, numeric: true) { |r| r.value }
      t.with_column(:status, header: "Status") { |r| r.status }
      extra&.call(t)
    end
  end

  it "renders a real table with a caption, column headers and one row per record" do
    render_table(sort_url:)
    expect(page).to have_css("table.dp-table__table caption", text: "Sensor readings")
    expect(page.all("thead th[scope='col']").map { _1.text.strip }).to eq(%w[Sensor Value Status])
    expect(page).to have_css("tbody tr", count: 3)
    expect(page.all("tbody tr").first.all("th, td").map { _1.text.strip }).to eq([ "Hull", "12.5", "ok" ])
  end

  it "needs a caption (it names the table for assistive tech)" do
    expect { described_class.new(rows:, caption: "") }.to raise_error(ArgumentError, /caption/)
    expect { described_class.new(rows:, caption: nil) }.to raise_error(ArgumentError, /caption/)
  end

  it "can hide the caption visually and keep it for screen readers" do
    render_table(sort_url:, caption_hidden: true)
    expect(page).to have_css("caption.dp-sr-only", text: "Sensor readings")
  end

  it "makes the scrolling wrapper a named, keyboard-focusable region" do
    render_table(sort_url:)
    wrap = page.find(".dp-table")
    expect(wrap[:role]).to eq("region")
    expect(wrap["aria-label"]).to eq("Sensor readings")
    expect(wrap[:tabindex]).to eq("0")
  end

  it "escapes cell content" do
    render_table(sort_url:)
    expect(page.native.to_html).to include("Deck &lt;7&gt;")
  end

  it "uses a row header cell for the column flagged row_header" do
    render_table(sort_url:)
    expect(page).to have_css("tbody tr:first-child th[scope='row']", text: "Hull")
    expect(page).to have_css("tbody tr:first-child td", count: 2)
  end

  it "aligns numeric and end-aligned columns" do
    render_table(sort_url:)
    expect(page).to have_css("thead th.dp-table__cell--end.dp-table__cell--numeric", text: "Value")
    expect(page).to have_css("tbody td.dp-table__cell--end.dp-table__cell--numeric", count: 3)
    render_inline(described_class.new(rows:, caption: "c")) { |t| t.with_column(:a, header: "A", align: :center) { "x" } }
    expect(page).to have_css("td.dp-table__cell--center")
  end

  describe "sorting (the host sorts, the component renders links and state)" do
    it "renders sortable headers as links to the ascending order first" do
      render_table(sort_url:)
      expect(page).to have_css("thead th a.dp-table__sort[href='/readings?sort=name&dir=asc']", text: "Sensor")
      expect(page).to have_css("thead th a[href='/readings?sort=value&dir=asc']")
      expect(page).not_to have_css("thead th a", text: "Status")
      expect(page).not_to have_css("thead th[aria-sort]")
    end

    it "marks the sorted column with aria-sort and links to the opposite direction" do
      render_table(sort_url:, sort: "value", dir: "asc")
      th = page.find("thead th", text: "Value")
      expect(th["aria-sort"]).to eq("ascending")
      expect(th).to have_css("a[href='/readings?sort=value&dir=desc']")
      expect(th).to have_css("svg.dp-icon[aria-hidden='true']")
      expect(th).to have_css(".dp-sr-only", text: "Sorted ascending")
      expect(page).to have_css("thead th[aria-sort]", count: 1)
    end

    it "handles descending, and translates the state" do
      I18n.with_locale(:fr) { render_table(sort_url:, sort: "name", dir: "desc") }
      th = page.find("thead th", text: "Sensor")
      expect(th["aria-sort"]).to eq("descending")
      expect(th).to have_css(".dp-sr-only", text: "Trié par ordre décroissant")
      expect(th).to have_css("a[href='/readings?sort=name&dir=asc']")
    end

    it "ignores a sort key or direction that does not come from a sortable column (it is user input)" do
      render_table(sort_url:, sort: "status", dir: "sideways")
      expect(page).not_to have_css("[aria-sort]")
      render_table(sort_url:, sort: "<script>", dir: "asc")
      expect(page).not_to have_css("[aria-sort]")
      expect(page.native.to_html).not_to include("<script>")
      render_table(sort_url:, sort: "name", dir: "bogus")
      expect(page.find("thead th", text: "Sensor")["aria-sort"]).to eq("ascending")
    end

    it "requires sort_url when a column is sortable" do
      expect { render_table }.to raise_error(ArgumentError, /sort_url/)
    end
  end

  describe "footer and empty state" do
    it "renders the footer slot in a tfoot (e.g. a totals row)" do
      render_table(sort_url:) { |t| t.with_footer { '<tr><th scope="row">Total</th><td>113.75</td><td></td></tr>'.html_safe } }
      expect(page).to have_css("tfoot tr th", text: "Total")
    end

    it "shows a translated message spanning every column when there are no rows" do
      render_table(rows: [], sort_url:)
      cell = page.find("tbody td.dp-table__empty")
      expect(cell[:colspan]).to eq("3")
      expect(cell.text).to eq("No data")
      I18n.with_locale(:fr) { render_table(rows: [], sort_url:) }
      expect(page.find("td.dp-table__empty").text).to eq("Aucune donnée")
    end

    it "accepts a custom empty slot" do
      render_table(rows: [], sort_url:) { |t| t.with_empty { "Nothing recorded yet" } }
      expect(page).to have_css("td.dp-table__empty", text: "Nothing recorded yet")
    end
  end

  describe "options" do
    it "supports sticky headers and zebra rows" do
      render_table(sort_url:, sticky: true, zebra: true)
      expect(page).to have_css(".dp-table.dp-table--sticky.dp-table--zebra")
    end

    it "can give each row an id (for Turbo Streams)" do
      render_table(sort_url:, row_id: ->(r) { "reading_#{r.id}" })
      expect(page).to have_css("tbody tr#reading_2")
    end

    it "accepts any enumerable of rows" do
      render_table(rows: rows.each, sort_url:)
      expect(page).to have_css("tbody tr", count: 3)
    end

    it "passes html options to the wrapper (a stable id lets a Turbo Stream replace the table)" do
      render_table(sort_url:, id: "readings", class: "x", data: { a: 1 })
      expect(page).to have_css("#readings.dp-table.x[data-a='1']")
    end
  end

  it "rejects invalid columns" do
    expect { render_inline(described_class.new(rows:, caption: "c")) { |t| t.with_column(:a, header: "") { "x" } } }.to raise_error(ArgumentError, /header/)
    expect { render_inline(described_class.new(rows:, caption: "c")) { |t| t.with_column(:a, header: "A", align: :left) { "x" } } }.to raise_error(ArgumentError, /align.*start, center, end/)
    expect { render_inline(described_class.new(rows:, caption: "c")) { |t| t.with_column(:a, header: "A") { "x" }; t.with_column(:a, header: "B") { "y" } } }.to raise_error(ArgumentError, /duplicate|unique/)
    expect { render_inline(described_class.new(rows:, caption: "c")) }.to raise_error(ArgumentError, /column/)
  end
end
