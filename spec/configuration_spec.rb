require "spec_helper"

RSpec.describe Deckplate::Configuration do
  after { Deckplate.reset_configuration! }

  it "has the SPEC section 7 defaults" do
    c = Deckplate.configuration
    expect(c.default_theme).to eq(:classic)
    expect(c.themes).to eq(%i[classic azure nocturne daylight crimson])
    expect(c.sounds).to be(false)
    expect(c.csp_safe_values).to be(false)
    expect(c.form_builder).to be(false)
    expect(c.strict_colors).to be(true) # test env is Rails.env.local?
  end

  it "is changed through Deckplate.configure" do
    Deckplate.configure do |c|
      c.default_theme = :azure
      c.sounds = true
    end
    expect(Deckplate.configuration.default_theme).to eq(:azure)
    expect(Deckplate.configuration.sounds).to be(true)
  end

  it "returns the same object between calls" do
    expect(Deckplate.configuration).to be(Deckplate.configuration)
  end

  it "rejects a default theme that is not in the theme list" do
    expect { Deckplate.configure { |c| c.default_theme = :nope } }
      .to raise_error(ArgumentError, /default_theme :nope.*classic, azure/)
  end

  it "rejects malformed theme names (they end up in data-dp-theme and CSS selectors)" do
    expect { Deckplate.configure { |c| c.themes = [ :classic, "Bad Theme!" ] } }
      .to raise_error(ArgumentError, /invalid theme name "Bad Theme!"/)
  end

  it "accepts custom themes created by the theme generator" do
    Deckplate.configure do |c|
      c.themes = %i[classic my-brand]
      c.default_theme = :"my-brand"
    end
    expect(Deckplate.configuration.default_theme).to eq(:"my-brand")
  end

  it "leaves the previous configuration untouched when validation fails" do
    expect { Deckplate.configure { |c| c.default_theme = :nope } }.to raise_error(ArgumentError)
    expect(Deckplate.configuration.default_theme).to eq(:classic)
  end

  it "accepts string theme names and normalises them to symbols" do
    Deckplate.configure { |c| c.default_theme = "daylight" }
    expect(Deckplate.configuration.default_theme).to eq(:daylight)
  end

  it "resets to defaults" do
    Deckplate.configure { |c| c.sounds = true }
    Deckplate.reset_configuration!
    expect(Deckplate.configuration.sounds).to be(false)
  end
end
