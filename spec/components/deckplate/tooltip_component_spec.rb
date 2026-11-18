require "spec_helper"

RSpec.describe Deckplate::TooltipComponent, type: :component do
  it "wraps the trigger and renders a tooltip bubble hidden by default" do
    render_inline(described_class.new(text: "Shield power", id: "tip-1")) { '<button type="button">Shields</button>'.html_safe }
    expect(page).to have_css(".dp-tooltip[data-controller='dp-tooltip'] button", text: "Shields", visible: :all)
    bubble = page.find("#tip-1", visible: :all)
    expect(bubble[:role]).to eq("tooltip")
    expect(bubble[:popover]).to eq("manual")
    expect(bubble.text(:all)).to eq("Shield power")
    expect(bubble["data-dp-tooltip-target"]).to eq("bubble")
  end

  it "wires hover, focus and Escape handling on the wrapper" do
    render_inline(described_class.new(text: "T", id: "t")) { "x" }
    actions = page.find(".dp-tooltip", visible: :all)["data-action"]
    expect(actions).to include("mouseenter->dp-tooltip#show", "mouseleave->dp-tooltip#hide", "focusin->dp-tooltip#show", "focusout->dp-tooltip#hide", "keydown->dp-tooltip#key")
  end

  it "derives a deterministic id from the text" do
    render_inline(described_class.new(text: "Shield power")) { "x" }
    expect(page).to have_css("#shield-power-tooltip[role='tooltip']", visible: :all)
  end

  it "passes html options through" do
    render_inline(described_class.new(text: "T", class: "x")) { "y" }
    expect(page).to have_css(".dp-tooltip.x", visible: :all)
  end

  it "rejects an empty text" do
    expect { described_class.new(text: "") }.to raise_error(ArgumentError, /text/)
  end

  it "places the bubble under the host and opens without delay by default" do
    render_inline(described_class.new(text: "T", id: "t")) { "x" }
    host = page.find(".dp-tooltip", visible: :all)
    expect(host["data-dp-tooltip-placement-value"]).to eq("bottom")
    expect(host["data-dp-tooltip-delay-value"]).to eq("0")
  end

  it "accepts a placement and a delay" do
    render_inline(described_class.new(text: "T", id: "t", placement: :start, delay: 400)) { "x" }
    host = page.find(".dp-tooltip", visible: :all)
    expect(host["data-dp-tooltip-placement-value"]).to eq("start")
    expect(host["data-dp-tooltip-delay-value"]).to eq("400")
  end

  it "rejects an unknown placement and a negative or non-integer delay" do
    expect { described_class.new(text: "T", placement: :middle) }.to raise_error(ArgumentError, /placement/)
    expect { described_class.new(text: "T", delay: -1) }.to raise_error(ArgumentError, /delay/)
    expect { described_class.new(text: "T", delay: "fast") }.to raise_error(ArgumentError, /delay/)
  end
end
