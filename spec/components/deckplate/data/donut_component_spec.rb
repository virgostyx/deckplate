require "spec_helper"

RSpec.describe Deckplate::Data::DonutComponent, type: :component do
  let(:series) { [ [ "Core", 50 ], [ "Shields", 30 ], [ "Engines", 20 ] ] }

  def donut(**options) = render_inline(described_class.new(label: "Power split", series: series, **options))
  def slices = page.all("circle.dp-donut__slice", visible: :all)
  def dash(slice) = slice["stroke-dasharray"].split.map(&:to_f)

  it "is a figure with a caption, a decorative SVG, a legend and a data table" do
    donut
    expect(page).to have_css("figure.dp-donut figcaption", text: "Power split", visible: :all)
    expect(page.find("svg.dp-donut__plot", visible: :all)["aria-hidden"]).to eq("true")
    expect(page.find("svg.dp-donut__plot", visible: :all)[:style]).to be_nil
    expect(page.find("div.dp-sr-only > table", visible: :all).all("tbody tr", visible: :all).map { |r| r.all("th, td", visible: :all).map { _1.text(:all) } })
      .to eq([ %w[Core 50 50%], %w[Shields 30 30%], %w[Engines 20 20%] ])
  end

  it "draws one slice per non-zero value, each as a share of 100 along the ring" do
    donut
    expect(slices.size).to eq(3)
    expect(slices.map { _1[:pathlength] || _1["pathLength"] }.uniq).to eq([ "100" ])
    visible = slices.map { dash(_1).first }
    expect(visible).to match([ be_within(0.01).of(49.5), be_within(0.01).of(29.5), be_within(0.01).of(19.5) ]) # a 0.5 gap before each slice's neighbour
    expect(slices.map { _1["stroke-dashoffset"].to_f }).to eq([ 0.0, -50.0, -80.0 ])
  end

  it "draws a single full slice without a gap, and skips zero values in the drawing but not in the legend" do
    render_inline(described_class.new(label: "L", series: [ [ "All", 7 ], [ "None", 0 ] ]))
    expect(slices.size).to eq(1)
    expect(dash(slices.first).first).to eq(100.0)
    expect(page.all(".dp-donut__legend li", visible: :all).size).to eq(2)
  end

  it "lists each slice in the legend with its value and share, in the order drawn" do
    donut
    expect(page.all(".dp-donut__legend li", visible: :all).map { _1.text(:all).squish }).to eq([ "Core 50 (50%)", "Shields 30 (30%)", "Engines 20 (20%)" ])
    classes = page.all(".dp-donut__legend li", visible: :all).map { _1[:class].split.grep(/dp-c-/) }
    expect(classes.uniq.size).to eq(3)
    expect(slices.map { _1[:class].split.grep(/dp-c-/) }.uniq.size).to eq(3)
  end

  it "shows the total in the middle, or a text of its own" do
    donut
    expect(page.find(".dp-donut__center", visible: :all).text(:all).squish).to eq("100 Total")
    donut(center: [ "75%", "Charge" ])
    expect(page.find(".dp-donut__center", visible: :all).text(:all).squish).to eq("75% Charge")
  end

  it "speaks French" do
    I18n.with_locale(:fr) { donut }
    expect(page.find(".dp-donut__center", visible: :all).text(:all).squish).to eq("100 Total")
    expect(page.find(".dp-sr-only caption", visible: :all).text(:all)).to eq("Données de Power split")
    expect(page.all(".dp-sr-only th[scope='col']", visible: :all).map { _1.text(:all) }).to eq([ "Élément", "Valeur", "Part" ])
  end

  it "accepts a Hash, escapes labels and passes html options through" do
    render_inline(described_class.new(label: "L", series: { "<b>x</b>" => 1, "y" => 1 }, class: "x", id: "d"))
    expect(page.native.to_html).not_to include("<b>x</b>")
    expect(page).to have_css("figure#d.dp-donut.x", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", series: series) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", series: []) }.to raise_error(ArgumentError, /series/)
    expect { described_class.new(label: "L", series: [ [ "A", 0 ] ]) }.to raise_error(ArgumentError, /greater than 0|total/)
    expect { described_class.new(label: "L", series: [ [ "A", -1 ], [ "B", 2 ] ]) }.to raise_error(ArgumentError, /value/)
    expect { described_class.new(label: "L", series: [ [ "A", "x" ] ]) }.to raise_error(ArgumentError, /value/)
    expect { described_class.new(label: "L", series: [ [ "", 1 ] ]) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", series: series, center: "x") }.to raise_error(ArgumentError, /center/)
  end
end
