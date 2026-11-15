require "spec_helper"

RSpec.describe Deckplate::Forms::FileInputComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", **opts)
  let(:control_css) { "input[type='file'].dp-input" }

  it_behaves_like "a form control"

  it "supports accept and multiple" do
    render_inline(build(accept: "image/png,image/jpeg", multiple: true))
    input = page.find("input[type='file']", visible: :all)
    expect(input[:accept]).to eq("image/png,image/jpeg")
    expect(input[:multiple]).not_to be_nil
  end
end
