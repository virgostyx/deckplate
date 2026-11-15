require "spec_helper"

RSpec.describe Deckplate::Data::GaugeComponent, type: :component do
  after { Deckplate.reset_configuration! }

  def gauge = page.find("[role='meter']", visible: :all)

  it "renders a meter with its name, value, range and a text value" do
    render_inline(described_class.new(label: "Power", value: 72))
    expect(gauge["aria-label"]).to eq("Power")
    expect([ gauge["aria-valuemin"], gauge["aria-valuemax"], gauge["aria-valuenow"] ]).to eq(%w[0 100 72])
    expect(gauge["aria-valuetext"]).to eq("72%")
    expect(page).to have_css(".dp-gauge__value", text: "72", visible: :all)
    expect(page).to have_css(".dp-gauge__label", text: "Power", visible: :all)
  end

  it "supports the radial and semicircle variants" do
    render_inline(described_class.new(label: "L", value: 10))
    expect(gauge[:class].split).to include("dp-gauge--radial")
    render_inline(described_class.new(label: "L", value: 10, variant: :semicircle))
    expect(gauge[:class].split).to include("dp-gauge--semicircle")
  end

  it "shows a custom unit instead of %" do
    render_inline(described_class.new(label: "Temp", value: 40, unit: "°"))
    expect(page).to have_css(".dp-gauge__unit", text: "°", visible: :all)
    expect(gauge["aria-valuetext"]).to eq("40°")
  end

  it "hides the decorative dial from assistive tech (the meter carries the values)" do
    render_inline(described_class.new(label: "L", value: 10))
    expect(page).to have_css(".dp-gauge__dial[aria-hidden='true']", visible: :all)
  end

  it "passes the percentage to the CSS: inline style by default, quantised class in CSP-safe mode" do
    render_inline(described_class.new(label: "L", value: 72))
    expect(gauge[:style]).to eq("--dp-value: 72")
    Deckplate.configure { |c| c.csp_safe_values = true }
    render_inline(described_class.new(label: "L", value: 72))
    expect(gauge[:style]).to be_nil
    expect(gauge[:class].split).to include("dp-v-72")
  end

  it "takes a colour and html options (a stable id lets a Turbo Stream replace it)" do
    render_inline(described_class.new(label: "L", value: 1, color: :warning, id: "power-gauge", class: "x"))
    expect(page).to have_css("#power-gauge.dp-gauge.dp-c-warning.x", visible: :all)
  end

  it "accepts the extremes" do
    render_inline(described_class.new(label: "L", value: 0))
    expect(gauge["aria-valuenow"]).to eq("0")
    render_inline(described_class.new(label: "L", value: 100))
    expect(gauge["aria-valuenow"]).to eq("100")
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", value: 1) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", value: 101) }.to raise_error(ArgumentError, /value/)
    expect { described_class.new(label: "L", value: nil) }.to raise_error(ArgumentError, /value/)
    expect { described_class.new(label: "L", value: 1, variant: :bar) }.to raise_error(ArgumentError, /variant.*radial, semicircle/)
  end
end
