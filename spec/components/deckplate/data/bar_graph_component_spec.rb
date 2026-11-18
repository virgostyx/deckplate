require "spec_helper"

RSpec.describe Deckplate::Data::BarGraphComponent, type: :component do
  after { Deckplate.reset_configuration! }

  let(:series) { [ [ "Alpha", 10 ], [ "Beta", 25 ], [ "Gamma", 50 ] ] }

  def build(**opts) = described_class.new(label: "Sensors", series: series, **opts)

  it "renders a figure with a caption and one bar per data point" do
    render_inline(build)
    expect(page).to have_css("figure.dp-bar-graph.dp-bar-graph--horizontal figcaption", text: "Sensors", visible: :all)
    expect(page).to have_css(".dp-bar-graph__bar", count: 3, visible: :all)
    expect(page.all(".dp-bar-graph__value", visible: :all).map(&:text)).to eq(%w[10 25 50])
  end

  it "scales the bars to the largest value by default, or to max:" do
    render_inline(build)
    expect(page.all(".dp-bar-graph__bar", visible: :all).map { _1[:style] }).to eq([ "--dp-value: 20", "--dp-value: 50", "--dp-value: 100" ])
    render_inline(build(max: 200))
    expect(page.all(".dp-bar-graph__bar", visible: :all).map { _1[:style] }).to eq([ "--dp-value: 5", "--dp-value: 12.5", "--dp-value: 25" ])
  end

  it "supports the vertical orientation" do
    render_inline(build(orientation: :vertical))
    expect(page).to have_css(".dp-bar-graph--vertical", visible: :all)
  end

  it "keeps the data available to everyone: the plot is decorative and a hidden table repeats it" do
    render_inline(build)
    expect(page).to have_css(".dp-bar-graph__plot[aria-hidden='true']", visible: :all)
    expect(page).to have_css("div.dp-sr-only > table", visible: :all)
    table = page.find("div.dp-sr-only > table", visible: :all)
    expect(table).to have_css("caption", text: "Data for Sensors", visible: :all)
    expect(table.all("th[scope='col']", visible: :all).map { _1.text(:all) }).to eq(%w[Item Value])
    expect(table.all("tbody tr", visible: :all).map { |r| r.all("th, td", visible: :all).map { _1.text(:all) } }).to eq([ %w[Alpha 10], %w[Beta 25], %w[Gamma 50] ])
    expect(table).to have_css("tbody th[scope='row']", count: 3, visible: :all)
  end

  it "translates the table texts" do
    I18n.with_locale(:fr) { render_inline(build) }
    expect(page.find(".dp-sr-only caption", visible: :all).text(:all)).to eq("Données de Sensors")
    expect(page.all(".dp-sr-only th[scope='col']", visible: :all).map { _1.text(:all) }).to eq(%w[Élément Valeur])
  end

  it "accepts a Hash and escapes labels" do
    render_inline(described_class.new(label: "L", series: { "<b>x</b>" => 1 }))
    expect(page.native.to_html).not_to include("<b>x</b>")
  end

  it "uses quantised classes and no style attribute in CSP-safe mode" do
    Deckplate.configure { |c| c.csp_safe_values = true }
    render_inline(build)
    bars = page.all(".dp-bar-graph__bar", visible: :all)
    expect(bars.map { _1[:style] }).to all(be_nil)
    expect(bars.map { _1[:class].split.grep(/dp-v-/) }).to eq([ [ "dp-v-20" ], [ "dp-v-50" ], [ "dp-v-100" ] ])
  end

  it "applies a colour and passes html options through" do
    render_inline(build(color: :accent, class: "x", id: "g"))
    expect(page).to have_css("figure#g.dp-bar-graph.dp-c-accent.x", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", series: series) }.to raise_error(ArgumentError, /label/)
    expect { build(series: []) }.to raise_error(ArgumentError, /series/)
    expect { build(series: [ [ "A", -1 ] ]) }.to raise_error(ArgumentError, /value/)
    expect { build(series: [ [ "A", "x" ] ]) }.to raise_error(ArgumentError, /value/)
    expect { build(series: [ [ "", 1 ] ]) }.to raise_error(ArgumentError, /label/)
    expect { build(max: 0) }.to raise_error(ArgumentError, /max/)
    expect { build(orientation: :diagonal) }.to raise_error(ArgumentError, /orientation.*horizontal, vertical/)
  end

  describe "several values per item (keys:)" do
    let(:rows) { [ [ "Mon", [ 10, 20 ] ], [ "Tue", [ 30, 40 ] ] ] }

    def multi(**opts) = described_class.new(label: "Power", series: rows, keys: %w[Core Shields], **opts)

    it "groups: one bar per key and item, scaled to the largest single value" do
      render_inline(multi)
      expect(page).to have_css(".dp-bar-graph--grouped", visible: :all)
      expect(page.all(".dp-bar-graph__bar", visible: :all).map { _1[:style] }).to eq([ "--dp-value: 25", "--dp-value: 50", "--dp-value: 75", "--dp-value: 100" ])
      expect(page.all(".dp-bar-graph__value", visible: :all).map { _1.text(:all) }).to eq(%w[10 20 30 40])
    end

    it "stacks: the bars of an item are consecutive segments scaled to the largest total, and the value is the total" do
      render_inline(multi(grouping: :stacked))
      expect(page).to have_css(".dp-bar-graph--stacked", visible: :all)
      expect(page).to have_css(".dp-bar-graph__row", count: 2, visible: :all)
      expect(page.all(".dp-bar-graph__row .dp-bar-graph__track", visible: :all).size).to eq(2) # one track per item
      percents = page.all(".dp-bar-graph__bar", visible: :all).map { _1[:style].split(": ").last.to_f }
      expect(percents).to match([ be_within(0.01).of(14.29), be_within(0.01).of(28.57), be_within(0.01).of(42.86), be_within(0.01).of(57.14) ])
      expect(page.all(".dp-bar-graph__value", visible: :all).map { _1.text(:all) }).to eq(%w[30 70])
    end

    it "tells keys apart without colour: a legend with names, a colour and a pattern class per key" do
      render_inline(multi)
      expect(page.all(".dp-bar-graph__legend li", visible: :all).map { _1.text(:all).strip }).to eq(%w[Core Shields])
      bars = page.all(".dp-bar-graph__row:first-child .dp-bar-graph__bar", visible: :all)
      expect(bars.map { _1[:class].split.grep(/dp-bar-graph__bar--k/) }).to eq([ [ "dp-bar-graph__bar--k0" ], [ "dp-bar-graph__bar--k1" ] ])
      expect(bars.map { _1[:class].split.grep(/dp-c-/) }.uniq.size).to eq(2)
    end

    it "repeats the data in the hidden table, with a Total column when stacked" do
      render_inline(multi)
      table = page.find("div.dp-sr-only > table", visible: :all)
      expect(table.all("th[scope='col']", visible: :all).map { _1.text(:all) }).to eq(%w[Item Core Shields])
      render_inline(multi(grouping: :stacked))
      table = page.find("div.dp-sr-only > table", visible: :all)
      expect(table.all("th[scope='col']", visible: :all).map { _1.text(:all) }).to eq(%w[Item Core Shields Total])
      expect(table.all("tbody tr", visible: :all).map { |r| r.all("th, td", visible: :all).map { _1.text(:all) } }).to eq([ %w[Mon 10 20 30], %w[Tue 30 40 70] ])
    end

    it "works vertically and with an explicit max" do
      render_inline(multi(orientation: :vertical, max: 80))
      expect(page).to have_css(".dp-bar-graph--vertical.dp-bar-graph--grouped", visible: :all)
      expect(page.all(".dp-bar-graph__bar", visible: :all).first[:style]).to eq("--dp-value: 12.5")
    end

    it "has no style attribute in CSP-safe mode" do
      Deckplate.configure { |c| c.csp_safe_values = true }
      render_inline(multi(grouping: :stacked))
      expect(page.all(".dp-bar-graph__bar", visible: :all).map { _1[:style] }).to all(be_nil)
    end

    it "translates the Total column" do
      I18n.with_locale(:fr) { render_inline(multi(grouping: :stacked)) }
      expect(page.all(".dp-sr-only th[scope='col']", visible: :all).map { _1.text(:all) }.last).to eq("Total")
    end

    it "rejects inconsistent input" do
      expect { described_class.new(label: "L", series: rows) }.to raise_error(ArgumentError, /keys/)
      expect { described_class.new(label: "L", series: rows, keys: %w[Core]) }.to raise_error(ArgumentError, /values/)
      expect { described_class.new(label: "L", series: [ [ "A", 1 ] ], keys: %w[Core]) }.to raise_error(ArgumentError, /values/)
      expect { described_class.new(label: "L", series: [ [ "A", [ 1, -2 ] ] ], keys: %w[Core Shields]) }.to raise_error(ArgumentError, /value/)
      expect { multi(grouping: :pile) }.to raise_error(ArgumentError, /grouping.*grouped, stacked/)
      expect { described_class.new(label: "L", series: rows, keys: [ "Core", "" ]) }.to raise_error(ArgumentError, /keys/)
    end
  end
end
