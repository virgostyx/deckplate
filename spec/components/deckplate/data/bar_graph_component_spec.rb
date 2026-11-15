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
    table = page.find("table.dp-sr-only", visible: :all)
    expect(table).to have_css("caption", text: "Data for Sensors", visible: :all)
    expect(table.all("th[scope='col']", visible: :all).map { _1.text(:all) }).to eq(%w[Item Value])
    expect(table.all("tbody tr", visible: :all).map { |r| r.all("th, td", visible: :all).map { _1.text(:all) } }).to eq([ %w[Alpha 10], %w[Beta 25], %w[Gamma 50] ])
    expect(table).to have_css("tbody th[scope='row']", count: 3, visible: :all)
  end

  it "translates the table texts" do
    I18n.with_locale(:fr) { render_inline(build) }
    expect(page.find("table.dp-sr-only caption", visible: :all).text(:all)).to eq("Données de Sensors")
    expect(page.all("table.dp-sr-only th[scope='col']", visible: :all).map { _1.text(:all) }).to eq(%w[Élément Valeur])
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
end
