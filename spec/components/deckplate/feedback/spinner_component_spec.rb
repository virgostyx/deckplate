require "spec_helper"

RSpec.describe Deckplate::Feedback::SpinnerComponent, type: :component do
  it "renders a decorative loader with a text for assistive technology, in a status region" do
    render_inline(described_class.new)
    spinner = page.find(".dp-spinner")
    expect(spinner[:role]).to eq("status")
    expect(spinner).to have_css(".dp-spinner__bars[aria-hidden='true'] span", count: 5)
    expect(spinner).to have_css(".dp-sr-only", text: "Loading")
  end

  it "translates, or takes a more precise label" do
    I18n.with_locale(:fr) { render_inline(described_class.new) }
    expect(page).to have_css(".dp-sr-only", text: "Chargement")
    render_inline(described_class.new(label: "Fetching sensor data"))
    expect(page).to have_css(".dp-sr-only", text: "Fetching sensor data")
  end

  it "supports sizes and colours" do
    %i[sm md lg].each do |size|
      render_inline(described_class.new(size:, color: :accent))
      expect(page).to have_css(".dp-spinner.dp-spinner--#{size}.dp-c-accent")
    end
  end

  it "can show the label next to the bars" do
    render_inline(described_class.new(label: "Saving", show_label: true))
    expect(page).to have_css(".dp-spinner__label", text: "Saving")
    expect(page).not_to have_css(".dp-sr-only", text: "Saving")
  end

  it "rejects invalid input" do
    expect { described_class.new(size: :xl) }.to raise_error(ArgumentError, /size.*sm, md, lg/)
    expect { described_class.new(label: "") }.to raise_error(ArgumentError, /label/)
  end
end
