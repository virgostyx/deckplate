require "spec_helper"

RSpec.describe Deckplate::Data::LineChartComponent, type: :component do
  let(:labels) { %w[Mon Tue Wed] }

  def chart(**options) = render_inline(described_class.new(label: "Reactor output", x_labels: labels, series: [ [ "Core", [ 0, 5, 10 ] ] ], **options))
  def points(index = 0) = page.all("polyline.dp-line-chart__line", visible: :all)[index][:points].split.map { _1.split(",").map(&:to_f) }

  it "is a figure with a caption, a decorative SVG and a data table for assistive tech" do
    chart
    expect(page).to have_css("figure.dp-line-chart figcaption", text: "Reactor output")
    expect(page.find("svg.dp-line-chart__plot", visible: :all)["aria-hidden"]).to eq("true")
    expect(page.find("svg.dp-line-chart__plot", visible: :all)[:style]).to be_nil
    table = page.find(".dp-sr-only table", visible: :all)
    expect(table.all("tbody tr", visible: :all).map { |row| row.all("th, td", visible: :all).map { _1.text(:all) } }).to eq([ %w[Mon 0], %w[Tue 5], %w[Wed 10] ])
    expect(table.all("thead th", visible: :all).map { _1.text(:all) }).to eq(%w[Point Core])
  end

  it "plots each point inside the plot area, the largest value at the top" do
    chart
    expect(points).to eq([ [ 44.0, 212.0 ], [ 256.0, 112.0 ], [ 468.0, 12.0 ] ])
  end

  it "draws round-number ticks from zero up to the largest value" do
    chart
    expect(page.all("text.dp-line-chart__y", visible: :all).map { _1.text(:all) }).to eq(%w[0 5 10])
    expect(page.all("text.dp-line-chart__x", visible: :all).map { _1.text(:all) }).to eq(labels)
    expect(page.all("line.dp-line-chart__grid", visible: :all).size).to eq(3)
  end

  it "rounds the axis up to a nice step (largest 87 gives 0, 50, 100)" do
    render_inline(described_class.new(label: "L", x_labels: %w[a b], series: [ [ "S", [ 12, 87 ] ] ]))
    expect(page.all("text.dp-line-chart__y", visible: :all).map { _1.text(:all) }).to eq(%w[0 50 100])
  end

  it "keeps a flat series and negative values drawable" do
    render_inline(described_class.new(label: "L", x_labels: %w[a b], series: [ [ "S", [ 4, 4 ] ] ]))
    expect(points.map(&:last).uniq.size).to eq(1)
    render_inline(described_class.new(label: "L", x_labels: %w[a b], series: [ [ "S", [ -10, 10 ] ] ]))
    expect(page.all("text.dp-line-chart__y", visible: :all).map { _1.text(:all) }).to include("-10", "0", "10")
  end

  it "fills under the line only when asked" do
    chart
    expect(page).not_to have_css("polygon.dp-line-chart__area", visible: :all)
    chart(area: true)
    expect(page).to have_css("polygon.dp-line-chart__area", visible: :all)
  end

  it "draws a labelled threshold, part of the axis range, and states it in the data" do
    chart(threshold: [ "Overload", 20 ])
    expect(page.all("text.dp-line-chart__y", visible: :all).map { _1.text(:all) }.last).to eq("20")
    expect(page).to have_css("line.dp-line-chart__threshold", visible: :all)
    expect(page.find("text.dp-line-chart__threshold-label", visible: :all).text(:all)).to eq("Overload")
    expect(page.find(".dp-sr-only", visible: :all).text(:all)).to include("Overload: 20")
  end

  it "tells series apart without colour: names in a legend, a different dash per line" do
    render_inline(described_class.new(label: "L", x_labels: %w[a b], series: [ [ "Core", [ 1, 2 ] ], [ "Shield", [ 2, 1 ] ] ]))
    expect(page.all(".dp-line-chart__legend li", visible: :all).map { _1.text(:all).strip }).to eq(%w[Core Shield])
    expect(page.all("polyline.dp-line-chart__line", visible: :all).map { _1["stroke-dasharray"] }.uniq.size).to eq(2)
    expect(page.all("g.dp-line-chart__series", visible: :all).map { _1[:class].split.grep(/dp-c-/) }.uniq.size).to eq(2)
  end

  it "has no legend for a single series" do
    chart
    expect(page).not_to have_css(".dp-line-chart__legend", visible: :all)
  end

  it "thins out the x labels of a long series" do
    render_inline(described_class.new(label: "L", x_labels: (1..20).map(&:to_s), series: [ [ "S", (1..20).to_a ] ]))
    expect(page.all("text.dp-line-chart__x", visible: :all).size).to be <= 10
  end

  it "speaks French" do
    I18n.with_locale(:fr) { chart(threshold: [ "Surcharge", 20 ]) }
    expect(page.find("table caption", visible: :all).text(:all)).to eq("Données de Reactor output")
    expect(page.find(".dp-sr-only", visible: :all).text(:all)).to include("Seuil", "Surcharge")
  end

  it "passes html options through" do
    chart(class: "x", id: "c1")
    expect(page).to have_css("figure#c1.dp-line-chart.x", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", x_labels: labels, series: [ [ "S", [ 1, 2, 3 ] ] ]) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", x_labels: [ "a" ], series: [ [ "S", [ 1 ] ] ]) }.to raise_error(ArgumentError, /x_labels/)
    expect { described_class.new(label: "L", x_labels: labels, series: []) }.to raise_error(ArgumentError, /series/)
    expect { described_class.new(label: "L", x_labels: labels, series: [ [ "S", [ 1, 2 ] ] ]) }.to raise_error(ArgumentError, /values/)
    expect { described_class.new(label: "L", x_labels: labels, series: [ [ "S", [ 1, 2, "x" ] ] ]) }.to raise_error(ArgumentError, /values/)
    expect { described_class.new(label: "L", x_labels: labels, series: [ [ "", [ 1, 2, 3 ] ] ]) }.to raise_error(ArgumentError, /name/)
    expect { described_class.new(label: "L", x_labels: labels, series: [ [ "S", [ 1, 2, 3 ] ] ], threshold: 5) }.to raise_error(ArgumentError, /threshold/)
  end
end
