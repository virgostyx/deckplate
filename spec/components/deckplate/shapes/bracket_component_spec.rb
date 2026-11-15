require "spec_helper"

RSpec.describe Deckplate::Shapes::BracketComponent, type: :component do
  def bracket = page.find(".dp-bracket")

  it "renders an open frame (start and end sides) around its content" do
    render_inline(described_class.new) { "Inside" }
    expect(bracket[:class].split).to include("dp-bracket", "dp-bracket--start", "dp-bracket--end", "dp-c-primary")
    expect(bracket[:class].split).not_to include("dp-bracket--top", "dp-bracket--bottom")
    expect(page).to have_css(".dp-bracket .dp-bracket__content", text: "Inside")
  end

  it "frames exactly the requested sides" do
    render_inline(described_class.new(sides: %i[top bottom])) { "x" }
    expect(bracket[:class].split).to include("dp-bracket--top", "dp-bracket--bottom")
    expect(bracket[:class].split).not_to include("dp-bracket--start", "dp-bracket--end")
  end

  it "accepts a single side given as a Symbol" do
    render_inline(described_class.new(sides: :top)) { "x" }
    expect(bracket[:class].split).to include("dp-bracket--top")
  end

  it "applies a colour and passes html options through" do
    render_inline(described_class.new(color: :info, class: "x", data: { a: 1 })) { "x" }
    expect(page).to have_css(".dp-bracket.dp-c-info.x[data-a='1']")
  end

  it "rejects invalid sides and colours" do
    expect { described_class.new(sides: [ :left ]) }.to raise_error(ArgumentError, /side.*:left.*top, bottom, start, end/)
    expect { described_class.new(sides: []) }.to raise_error(ArgumentError, /sides/)
    expect { described_class.new(color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
