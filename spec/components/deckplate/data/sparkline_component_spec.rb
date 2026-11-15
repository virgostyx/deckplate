require "spec_helper"

RSpec.describe Deckplate::Data::SparklineComponent, type: :component do
  def svg = page.find("svg.dp-sparkline", visible: :all)

  it "draws the points as an SVG polyline (server-rendered, no style attribute)" do
    render_inline(described_class.new(label: "Power", points: [ 0, 5, 10 ]))
    expect(svg[:role]).to eq("img")
    expect(svg[:style]).to be_nil
    poly = page.find("svg polyline", visible: :all)
    coords = poly[:points].split.map { _1.split(",").map(&:to_f) }
    expect(coords.map(&:first)).to eq([ 0.0, 50.0, 100.0 ])
    expect(coords.map(&:last)).to eq([ 29.0, 15.0, 1.0 ]) # the largest value is at the top, with a 1 unit margin
  end

  it "summarises the data for assistive tech" do
    render_inline(described_class.new(label: "Power", points: [ 3, 9, 1, 7 ]))
    expect(svg["aria-label"]).to eq("Power: from 3 to 7, minimum 1, maximum 9")
    I18n.with_locale(:fr) { render_inline(described_class.new(label: "Puissance", points: [ 3, 9, 1, 7 ])) }
    expect(svg["aria-label"]).to eq("Puissance : de 3 à 7, minimum 1, maximum 9")
  end

  it "draws a flat series in the middle" do
    render_inline(described_class.new(label: "L", points: [ 4, 4, 4 ]))
    expect(page.find("polyline", visible: :all)[:points].split.map { _1.split(",").last }.uniq).to eq([ "15.0" ])
  end

  it "formats decimals compactly" do
    render_inline(described_class.new(label: "L", points: [ 1.5, 2.25 ]))
    expect(svg["aria-label"]).to include("from 1.5 to 2.25")
  end

  it "stretches with its container and takes a colour" do
    render_inline(described_class.new(label: "L", points: [ 1, 2 ], color: :info, class: "x"))
    expect(svg[:viewbox] || svg["viewBox"]).to eq("0 0 100 30")
    expect(svg[:class].split).to include("dp-c-info", "x")
    expect(svg[:preserveaspectratio] || svg["preserveAspectRatio"]).to eq("none")
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", points: [ 1, 2 ]) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", points: [ 1 ]) }.to raise_error(ArgumentError, /points/)
    expect { described_class.new(label: "L", points: [ 1, "x" ]) }.to raise_error(ArgumentError, /points/)
  end
end
