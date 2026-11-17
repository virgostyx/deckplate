require "spec_helper"

RSpec.describe Deckplate::Shapes::ElbowComponent, type: :component do
  def elbow = page.find(".dp-elbow", visible: :all)

  it "renders a decorative top-left elbow of medium size in the default colour" do
    render_inline(described_class.new)
    expect(elbow[:class].split).to include("dp-elbow", "dp-elbow--top-left", "dp-elbow--md", "dp-c-primary")
    expect(elbow["aria-hidden"]).to eq("true")
    expect(elbow.text).to eq("")
  end

  it "supports the four corners" do
    %i[top_left top_right bottom_left bottom_right].each do |corner|
      render_inline(described_class.new(corner:))
      expect(page).to have_css(".dp-elbow.dp-elbow--#{corner.to_s.tr('_', '-')}", visible: :all)
    end
  end

  it "supports logical corners that mirror with the text direction (start/end), next to the physical ones" do
    %i[top_start top_end bottom_start bottom_end].each do |corner|
      render_inline(described_class.new(corner:))
      expect(page).to have_css(".dp-elbow.dp-elbow--#{corner.to_s.tr('_', '-')}", visible: :all)
    end
  end

  it "lists logical and physical corners when the corner is unknown" do
    expect { described_class.new(corner: :middle) }.to raise_error(ArgumentError, /top_start.*top_left|top_left.*top_start/)
  end

  it "supports the three named sizes" do
    %i[sm md lg].each do |size|
      render_inline(described_class.new(size:))
      expect(page).to have_css(".dp-elbow.dp-elbow--#{size}", visible: :all)
    end
  end

  it "applies a colour from a role or palette stop" do
    render_inline(described_class.new(color: :hopbush))
    expect(elbow[:class].split).to include("dp-c-hopbush")
  end

  describe "custom dimensions" do
    it "overrides width and height with layout units" do
      render_inline(described_class.new(width: 9, height: 6.5))
      expect(elbow[:style]).to eq("--dp-elbow-w: calc(9 * var(--dp-u)); --dp-elbow-h: calc(6.5 * var(--dp-u))")
    end

    it "can override one dimension only" do
      render_inline(described_class.new(height: 12))
      expect(elbow[:style]).to eq("--dp-elbow-h: calc(12 * var(--dp-u))")
    end

    it "emits no style when sizes are not customised" do
      render_inline(described_class.new)
      expect(elbow[:style]).to be_nil
    end
  end

  describe "label" do
    it "shows the label inside the elbow and exposes it to assistive tech" do
      render_inline(described_class.new(corner: :bottom_left)) { |e| e.with_label { "03-111968" } }
      expect(page).to have_css(".dp-elbow .dp-elbow__label", text: "03-111968")
      expect(elbow["aria-hidden"]).to be_nil
    end
  end

  it "passes class, data and aria through" do
    render_inline(described_class.new(class: "x", data: { a: 1 }, aria: { label: "L" }))
    expect(page).to have_css(".dp-elbow.x[data-a='1'][aria-label='L']", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(corner: :middle) }.to raise_error(ArgumentError, /corner.*top_left, top_right, bottom_left, bottom_right/)
    expect { described_class.new(size: :xl) }.to raise_error(ArgumentError, /size.*sm, md, lg/)
    expect { described_class.new(width: -1) }.to raise_error(ArgumentError, /size/)
    expect { described_class.new(height: "6") }.to raise_error(ArgumentError, /number/)
    expect { described_class.new(color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
