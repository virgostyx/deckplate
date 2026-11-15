require "spec_helper"

RSpec.describe Deckplate::Forms::RangeComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", value: 10, **opts)
  let(:control_css) { "input[type='range']" }

  it_behaves_like "a form control", supports_required: false

  it "reuses the slider: a native range with a live readout" do
    render_inline(build(min: 0, max: 50, step: 5, value: 25, unit: " kW"))
    expect(page).to have_css(".dp-slider[data-controller~='dp-slider'] input[type='range'][min='0'][max='50'][step='5'][value='25']", visible: :all)
    expect(page).to have_css("output", text: "25 kW", visible: :all)
  end
end
