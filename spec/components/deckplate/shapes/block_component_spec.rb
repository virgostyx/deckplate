require "spec_helper"

RSpec.describe Deckplate::Shapes::BlockComponent, type: :component do
  def block = page.find(".dp-block")

  it "renders a square block in the default colour around its content" do
    render_inline(described_class.new) { "Overview" }
    expect(block[:class].split).to include("dp-block", "dp-block--square", "dp-block--align-end", "dp-c-primary")
    expect(page).to have_css(".dp-block .dp-block__content", text: "Overview")
    expect(page).not_to have_css(".dp-block__number")
  end

  it "supports every shape and alignment" do
    %i[square pill start end].each do |shape|
      render_inline(described_class.new(shape:)) { "x" }
      expect(page).to have_css(".dp-block.dp-block--#{shape}")
    end
    %i[start center end].each do |align|
      render_inline(described_class.new(align:)) { "x" }
      expect(page).to have_css(".dp-block.dp-block--align-#{align}")
    end
  end

  it "shows an optional number before the content" do
    render_inline(described_class.new(number: "03")) { "Navigation" }
    expect(page).to have_css(".dp-block .dp-block__number", text: "03")
    expect(page.find(".dp-block").text.squish).to eq("03 Navigation")
  end

  it "accepts a number given as an Integer" do
    render_inline(described_class.new(number: 7)) { "x" }
    expect(page).to have_css(".dp-block__number", text: "7")
  end

  it "applies a role or palette stop colour" do
    render_inline(described_class.new(color: :lilac)) { "x" }
    expect(block[:class].split).to include("dp-c-lilac")
  end

  it "can render as another element" do
    render_inline(described_class.new(tag: :li)) { "x" }
    expect(page).to have_css("li.dp-block")
    render_inline(described_class.new(tag: :span)) { "x" }
    expect(page).to have_css("span.dp-block")
  end

  it "passes class, data and aria through" do
    render_inline(described_class.new(class: "x", data: { a: 1 }, aria: { label: "L" })) { "c" }
    expect(page).to have_css(".dp-block.x[data-a='1'][aria-label='L']")
  end

  it "rejects invalid input" do
    expect { described_class.new(shape: :round) }.to raise_error(ArgumentError, /shape.*square, pill, start, end/)
    expect { described_class.new(align: :left) }.to raise_error(ArgumentError, /align.*start, center, end/)
    expect { described_class.new(tag: :script) }.to raise_error(ArgumentError, /tag.*div, span, li/)
    expect { described_class.new(color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
