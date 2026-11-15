require "spec_helper"

RSpec.describe Deckplate::Data::DataCascadeComponent, type: :component do
  it "renders a purely decorative grid of numbers, hidden from assistive tech" do
    render_inline(described_class.new(columns: 4, rows: 5))
    el = page.find(".dp-data-cascade", visible: :all)
    expect(el["aria-hidden"]).to eq("true")
    expect(page).to have_css(".dp-data-cascade__column", count: 4, visible: :all)
    expect(page.all(".dp-data-cascade__column", visible: :all).first.all("span", visible: :all).size).to eq(5)
  end

  it "is render-pure: the same seed gives the same numbers (no randomness at render time)" do
    a = render_inline(described_class.new(columns: 3, rows: 3, seed: 42)).to_html
    b = render_inline(described_class.new(columns: 3, rows: 3, seed: 42)).to_html
    c = render_inline(described_class.new(columns: 3, rows: 3, seed: 43)).to_html
    expect(a).to eq(b)
    expect(a).not_to eq(c)
  end

  it "produces numbers of a fixed width, so columns stay aligned" do
    render_inline(described_class.new(columns: 2, rows: 4, digits: 5))
    expect(page.all(".dp-data-cascade__column span", visible: :all).map { _1.text(:all) }).to all(match(/\A\d{5}\z/))
  end

  it "takes a colour and passes html options through" do
    render_inline(described_class.new(color: :warning, class: "x"))
    expect(page).to have_css(".dp-data-cascade.dp-c-warning.x", visible: :all)
  end

  it "rejects invalid sizes" do
    expect { described_class.new(columns: 0) }.to raise_error(ArgumentError, /columns/)
    expect { described_class.new(rows: 101) }.to raise_error(ArgumentError, /rows/)
    expect { described_class.new(digits: 0) }.to raise_error(ArgumentError, /digits/)
  end
end
