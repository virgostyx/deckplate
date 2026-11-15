require "spec_helper"

RSpec.describe Deckplate::Shapes::CapComponent, type: :component do
  it "renders a decorative half-pill in the default colour" do
    render_inline(described_class.new)
    el = page.find(".dp-cap", visible: :all)
    expect(el[:class].split).to include("dp-cap--end", "dp-c-primary")
    expect(el["aria-hidden"]).to eq("true")
  end

  it "supports both sides and any colour" do
    render_inline(described_class.new(side: :start, color: :info))
    expect(page).to have_css(".dp-cap.dp-cap--start.dp-c-info", visible: :all)
  end

  it "passes html options through" do
    render_inline(described_class.new(class: "x", id: "c1"))
    expect(page).to have_css("#c1.dp-cap.x", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(side: :top) }.to raise_error(ArgumentError, /side.*start, end/)
    expect { described_class.new(color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
