require "spec_helper"
require "yaml"

RSpec.describe "config/deckplate/palette.yml" do
  let(:stops) { YAML.load_file(Deckplate::Engine.root.join("config/deckplate/palette.yml")).fetch("stops") }

  it "has 39 unique, correctly formatted stops with an ink each" do
    expect(stops.size).to eq(39)
    stops.each_value do |s|
      expect(s["hex"]).to match(/\A#\h{6}\z/)
      expect(s["ink"]).to match(/\A#\h{6}\z/)
    end
    expect(stops.values.map { |s| s["hex"] }.tally.values.max).to eq(1)
  end

  it "applies the SPEC corrections" do
    expect(stops).to include("signal-red", "atomic-tangerine")
    expect(stops).not_to include("sandy-brown", "red-alert", "emergency")
    expect(stops.dig("navy-blue", "background_only")).to be(true)
  end
end
