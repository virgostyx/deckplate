require "spec_helper"

RSpec.describe "Deckplate engine" do
  it "boots the dummy app with the engine loaded" do
    expect(Rails.application).to be_present
    expect(Rails.application.railties.map(&:class)).to include(Deckplate::Engine)
  end

  it "exposes a version" do
    expect(Deckplate::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end
end
