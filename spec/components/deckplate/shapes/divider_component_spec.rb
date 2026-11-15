require "spec_helper"

RSpec.describe Deckplate::Shapes::DividerComponent, type: :component do
  it "renders a solid decorative rule by default" do
    render_inline(described_class.new)
    el = page.find(".dp-divider", visible: :all)
    expect(el["aria-hidden"]).to eq("true")
    expect(el[:class].split).to include("dp-c-primary")
    expect(page).to have_css(".dp-divider__segment", count: 1, visible: :all)
  end

  it "splits into N equal segments" do
    render_inline(described_class.new(segments: 4, color: :info))
    expect(page).to have_css(".dp-divider__segment", count: 4, visible: :all)
  end

  it "accepts one colour per segment" do
    render_inline(described_class.new(segments: %i[primary secondary neon_carrot]))
    classes = page.all(".dp-divider__segment", visible: :all).map { _1[:class] }
    expect(classes[0]).to include("dp-c-primary")
    expect(classes[1]).to include("dp-c-secondary")
    expect(classes[2]).to include("dp-c-neon-carrot")
  end

  it "passes html options through" do
    render_inline(described_class.new(class: "x", data: { k: "v" }))
    expect(page).to have_css(".dp-divider.x[data-k='v']", visible: :all)
  end

  it "rejects invalid segments and colours" do
    expect { described_class.new(segments: 0) }.to raise_error(ArgumentError, /segments/)
    expect { described_class.new(segments: []) }.to raise_error(ArgumentError, /segments/)
    expect { described_class.new(segments: [ :nope ]) }.to raise_error(ArgumentError, /unknown colour/)
    expect { described_class.new(segments: "3") }.to raise_error(ArgumentError, /segments/)
  end
end
