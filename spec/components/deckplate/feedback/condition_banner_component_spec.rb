require "spec_helper"

RSpec.describe Deckplate::Feedback::ConditionBannerComponent, type: :component do
  def banner = page.find(".dp-condition-banner")

  it "always shows a text, with an icon, for every condition" do
    { normal: "Condition normal", caution: "Caution", critical: "Critical condition" }.each do |condition, text|
      render_inline(described_class.new(condition:))
      expect(banner).to have_css(".dp-condition-banner__label", text: text)
      expect(banner).to have_css("svg.dp-icon[aria-hidden='true']")
      expect(banner[:class].split).to include("dp-condition-banner--#{condition}")
    end
  end

  it "defaults to normal, announced politely; critical is an alert, caution a status" do
    render_inline(described_class.new)
    expect(banner[:class].split).to include("dp-condition-banner--normal", "dp-c-success")
    expect(banner[:role]).to eq("status")
    render_inline(described_class.new(condition: :caution))
    expect(banner[:role]).to eq("status")
    expect(banner[:class].split).to include("dp-c-warning")
    render_inline(described_class.new(condition: :critical))
    expect(banner[:role]).to eq("alert")
    expect(banner[:class].split).to include("dp-c-emergency")
  end

  it "has a non-motion cue for the critical condition (a marker element, not only the pulse)" do
    render_inline(described_class.new(condition: :critical))
    expect(banner).to have_css(".dp-condition-banner__marker[aria-hidden='true']")
    expect(banner[:class].split).to include("dp-condition-banner--critical")
  end

  it "switches to the crimson theme when critical (SPEC 5.5), and only then" do
    render_inline(described_class.new(condition: :critical))
    expect(banner["data-dp-theme"]).to eq("crimson")
    render_inline(described_class.new(condition: :caution))
    expect(banner["data-dp-theme"]).to be_nil
  end

  it "does not pin a theme the host did not enable" do
    Deckplate.configure { |c| c.themes = %i[classic]; c.default_theme = :classic }
    render_inline(described_class.new(condition: :critical))
    expect(banner["data-dp-theme"]).to be_nil
  ensure
    Deckplate.reset_configuration!
  end

  it "takes a custom label and extra content" do
    render_inline(described_class.new(condition: :caution, label: "Radiation")) { "Avoid deck 4" }
    expect(banner).to have_css(".dp-condition-banner__label", text: "Radiation")
    expect(banner).to have_css(".dp-condition-banner__detail", text: "Avoid deck 4")
  end

  it "translates the default texts" do
    I18n.with_locale(:fr) { render_inline(described_class.new(condition: :critical)) }
    expect(banner).to have_css(".dp-condition-banner__label", text: "État critique")
  end

  it "passes html options through" do
    render_inline(described_class.new(id: "cb", class: "x"))
    expect(page).to have_css("#cb.dp-condition-banner.x")
  end

  it "rejects an unknown condition and an empty label" do
    expect { described_class.new(condition: :panic) }.to raise_error(ArgumentError, /condition.*normal, caution, critical/)
    expect { described_class.new(label: "") }.to raise_error(ArgumentError, /label/)
  end
end
