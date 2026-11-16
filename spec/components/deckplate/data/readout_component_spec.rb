require "spec_helper"

RSpec.describe Deckplate::Data::ReadoutComponent, type: :component do
  def readout = page.find(".dp-readout")

  it "renders a label and its value" do
    render_inline(described_class.new(label: "Power", value: "72.4"))
    expect(readout).to have_css(".dp-readout__label", text: "Power")
    expect(readout).to have_css(".dp-readout__number", text: "72.4")
    expect(readout[:class].split).to include("dp-c-info")
  end

  it "shows a unit next to the value" do
    render_inline(described_class.new(label: "Power", value: 72.4, unit: "kW"))
    expect(readout.find(".dp-readout__value").text.squish).to eq("72.4 kW")
    expect(readout).to have_css(".dp-readout__unit", text: "kW")
  end

  it "accepts numbers and strings without formatting them (the caller owns precision)" do
    render_inline(described_class.new(label: "L", value: 0.10))
    expect(readout).to have_css(".dp-readout__number", text: "0.1")
    render_inline(described_class.new(label: "L", value: "0.10"))
    expect(readout).to have_css(".dp-readout__number", text: "0.10")
  end

  describe "trend" do
    {
      up: [ "Rising", "chevron_up" ], down: [ "Falling", "chevron_down" ], flat: [ "Steady", "minus" ]
    }.each do |trend, (text, icon)|
      it "shows #{trend} with an icon and a text alternative, never colour alone" do
        render_inline(described_class.new(label: "L", value: 1, trend:))
        expect(readout).to have_css(".dp-readout__trend.dp-readout__trend--#{trend}")
        expect(readout).to have_css(".dp-readout__trend svg.dp-icon[aria-hidden='true']")
        expect(readout).to have_css(".dp-readout__trend .dp-sr-only", text: text)
        expect(Deckplate::Helpers::ICONS).to have_key(icon.to_sym)
      end
    end

    it "translates the text alternative and shows no trend by default" do
      I18n.with_locale(:fr) { render_inline(described_class.new(label: "L", value: 1, trend: :up)) }
      expect(readout).to have_css(".dp-sr-only", text: "En hausse")
      render_inline(described_class.new(label: "L", value: 1))
      expect(page).not_to have_css(".dp-readout__trend")
    end
  end

  it "shows a dash with a text alternative when there is no value" do
    render_inline(described_class.new(label: "L", value: nil))
    expect(readout).to have_css(".dp-readout__number", text: "—")
    expect(readout).to have_css(".dp-sr-only", text: "No value")
  end

  it "can flicker when a Turbo Stream replaces it (opt-in): the controller is only there when asked" do
    render_inline(described_class.new(label: "L", value: 1))
    expect(readout["data-controller"]).to be_nil
    render_inline(described_class.new(label: "L", value: 1, flicker: true))
    expect(readout["data-controller"]).to eq("dp-flicker")
  end

  it "takes any colour, and passes html options through (a stable id lets Turbo Streams replace it)" do
    render_inline(described_class.new(label: "L", value: 1, color: :warning, id: "power", class: "x", data: { a: 1 }))
    expect(page).to have_css("#power.dp-readout.dp-c-warning.x[data-a='1']")
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", value: 1) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", value: 1, trend: :sideways) }.to raise_error(ArgumentError, /trend.*up, down, flat/)
    expect { described_class.new(label: "L", value: 1, color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
