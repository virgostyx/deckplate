require "spec_helper"

RSpec.describe Deckplate::Shapes::SpacerComponent, type: :component do
  it "renders a decorative, empty element sized in layout units" do
    render_inline(described_class.new(size: 2))
    el = page.find(".dp-spacer", visible: :all)
    expect(el["aria-hidden"]).to eq("true")
    expect(el[:style]).to eq("--dp-n: 2")
    expect(el.text).to eq("")
  end

  it "defaults to one unit on the block axis" do
    render_inline(described_class.new)
    expect(page).to have_css(".dp-spacer.dp-spacer--block", visible: :all)
    expect(page.find(".dp-spacer", visible: :all)[:style]).to eq("--dp-n: 1")
  end

  it "supports the inline axis and fractional sizes" do
    render_inline(described_class.new(size: 0.25, axis: :inline))
    expect(page).to have_css(".dp-spacer.dp-spacer--inline", visible: :all)
    expect(page.find(".dp-spacer", visible: :all)[:style]).to eq("--dp-n: 0.25")
  end

  it "passes class, data and aria through" do
    render_inline(described_class.new(class: "x", data: { a: 1 }))
    expect(page).to have_css(".dp-spacer.x[data-a='1']", visible: :all)
  end

  it "rejects invalid sizes and axes" do
    expect { described_class.new(size: -1) }.to raise_error(ArgumentError, /size/)
    expect { described_class.new(size: "2") }.to raise_error(ArgumentError, /number/)
    expect { described_class.new(axis: :diagonal) }.to raise_error(ArgumentError, /axis.*block, inline/)
  end
end
