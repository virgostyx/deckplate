require "spec_helper"

RSpec.describe Deckplate::Feedback::CalloutComponent, type: :component do
  def callout = page.find(".dp-callout")

  it "renders a note with its content, a text label and a distinct icon" do
    render_inline(described_class.new(kind: :tip)) { "Use the keyboard." }
    expect(callout[:role]).to eq("note")
    expect(callout[:class].split).to include("dp-callout--tip", "dp-c-info")
    expect(callout).to have_css(".dp-callout__body", text: "Use the keyboard.")
    expect(callout).to have_css("svg.dp-icon[aria-hidden='true']")
    expect(callout).to have_css(".dp-callout__kind", text: "Tip")
  end

  it "supports note, tip and warning, each with its own colour" do
    { note: "accent", tip: "info", warning: "warning" }.each do |kind, role|
      render_inline(described_class.new(kind:)) { "x" }
      expect(callout[:class].split).to include("dp-c-#{role}")
    end
  end

  it "takes a custom title instead of the kind word, and translates" do
    render_inline(described_class.new(title: "Careful")) { "x" }
    expect(callout).to have_css(".dp-callout__kind", text: "Careful")
    I18n.with_locale(:fr) { render_inline(described_class.new(kind: :warning)) { "x" } }
    expect(callout).to have_css(".dp-callout__kind", text: "Avertissement")
  end

  it "rejects an unknown kind" do
    expect { described_class.new(kind: :fatal) }.to raise_error(ArgumentError, /kind.*note, tip, warning/)
  end
end
