require "spec_helper"

RSpec.describe Deckplate::DisclosureComponent, type: :component do
  it "renders a native details element with a summary and a body" do
    render_inline(described_class.new(summary: "Details")) { "Hidden content" }
    expect(page).to have_css("details.dp-disclosure summary.dp-disclosure__summary", text: "Details")
    expect(page).to have_css("details .dp-disclosure__body", text: "Hidden content", visible: :all)
    expect(page.find("details")[:open]).to be_nil
  end

  it "can start open" do
    render_inline(described_class.new(summary: "Details", open: true)) { "x" }
    expect(page.find("details")[:open]).not_to be_nil
  end

  it "marks the toggle indicator as decorative" do
    render_inline(described_class.new(summary: "S")) { "x" }
    expect(page).to have_css("summary .dp-disclosure__marker[aria-hidden='true']")
  end

  it "applies a colour and passes html options through" do
    render_inline(described_class.new(summary: "S", color: :info, class: "x", data: { a: 1 })) { "b" }
    expect(page).to have_css("details.dp-disclosure.dp-c-info.x[data-a='1']")
  end

  it "rejects a missing summary and unknown colours" do
    expect { described_class.new(summary: "") }.to raise_error(ArgumentError, /summary/)
    expect { described_class.new(summary: "S", color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
