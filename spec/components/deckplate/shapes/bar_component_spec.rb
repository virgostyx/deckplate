require "spec_helper"

RSpec.describe Deckplate::Shapes::BarComponent, type: :component do
  def bar = page.find(".dp-bar", visible: :all)

  it "renders a decorative horizontal bar in the default colour" do
    render_inline(described_class.new)
    expect(bar[:class].split).to include("dp-bar", "dp-bar--horizontal", "dp-bar--none", "dp-c-primary")
    expect(bar["aria-hidden"]).to eq("true")
    expect(page).to have_css(".dp-bar__segment", count: 1, visible: :all)
  end

  it "supports the vertical orientation and every caps value" do
    render_inline(described_class.new(orientation: :vertical, caps: :both))
    expect(bar[:class].split).to include("dp-bar--vertical", "dp-bar--both")
    %i[none start end both].each do |caps|
      render_inline(described_class.new(caps:))
      expect(page).to have_css(".dp-bar.dp-bar--#{caps}", visible: :all)
    end
  end

  it "applies a colour from a role or palette stop" do
    render_inline(described_class.new(color: :neon_carrot))
    expect(bar[:class].split).to include("dp-c-neon-carrot")
  end

  it "sets a custom thickness in layout units" do
    render_inline(described_class.new(thickness: 2.5))
    expect(bar[:style]).to eq("--dp-bar-t: 2.5")
  end

  it "grows to fill its flex/grid parent when asked" do
    render_inline(described_class.new(fill: true))
    expect(bar[:class].split).to include("dp-bar--fill")
  end

  describe "title" do
    it "shows the title inside the bar and makes the bar readable by assistive tech" do
      render_inline(described_class.new) { |b| b.with_title { "Engineering" } }
      expect(page).to have_css(".dp-bar .dp-bar__title", text: "Engineering")
      expect(bar["aria-hidden"]).to be_nil
    end
  end

  describe "segments" do
    it "renders one coloured block per segment instead of the implicit one" do
      render_inline(described_class.new) do |b|
        b.with_segment(color: :info)
        b.with_segment(color: :warning, size: 3)
        b.with_segment(color: :danger) { "!" }
      end
      segs = page.all(".dp-bar__segment", visible: :all)
      expect(segs.size).to eq(3)
      expect(segs.map { _1[:class] }).to match([ /dp-c-info/, /dp-c-warning/, /dp-c-danger/ ])
      expect(segs[1][:style]).to eq("--dp-seg: 3")
      expect(segs[1][:class].split).to include("dp-bar__segment--sized")
      expect(segs[0][:class].split).not_to include("dp-bar__segment--sized")
      expect(segs[0][:style]).to be_nil
      expect(segs[2].text).to eq("!")
    end

    it "is readable (not aria-hidden) when a segment carries content" do
      render_inline(described_class.new) { |b| b.with_segment(color: :info) { "OK" } }
      expect(bar["aria-hidden"]).to be_nil
    end

    it "stays decorative when segments are empty" do
      render_inline(described_class.new) { |b| b.with_segment(color: :info) }
      expect(bar["aria-hidden"]).to eq("true")
    end

    it "rejects invalid segment input" do
      expect { render_inline(described_class.new) { |b| b.with_segment(color: :nope) } }.to raise_error(ArgumentError, /unknown colour/)
      expect { render_inline(described_class.new) { |b| b.with_segment(size: -2) } }.to raise_error(ArgumentError, /size/)
    end
  end

  it "passes class, data and aria through" do
    render_inline(described_class.new(class: "x", data: { a: 1 }, aria: { label: "L" }))
    expect(page).to have_css(".dp-bar.x[data-a='1'][aria-label='L']", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(orientation: :diagonal) }.to raise_error(ArgumentError, /orientation.*horizontal, vertical/)
    expect { described_class.new(caps: :left) }.to raise_error(ArgumentError, /caps.*none, start, end, both/)
    expect { described_class.new(thickness: -1) }.to raise_error(ArgumentError, /size/)
    expect { described_class.new(color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
