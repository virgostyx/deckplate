require "spec_helper"

RSpec.describe Deckplate::TabsComponent, type: :component do
  def render_tabs(**opts)
    render_inline(described_class.new(**opts)) do |t|
      t.with_tab(label: "Overview", id: "overview") { "Overview panel" }
      t.with_tab(label: "Crew", id: "crew") { "Crew panel" }
      t.with_tab(label: "Cargo", id: "cargo") { "Cargo panel" }
    end
  end

  it "renders the APG tabs structure and wires the controller" do
    render_tabs(label: "Ship sections")
    expect(page).to have_css(".dp-tabs[data-controller='dp-tabs']", visible: :all)
    expect(page).to have_css("[role='tablist'][aria-label='Ship sections'] [role='tab']", count: 3, visible: :all)
    expect(page).to have_css("[role='tabpanel']", count: 3, visible: :all)
  end

  it "links every tab to its panel in both directions with deterministic ids" do
    render_tabs
    tab = page.find("#overview-tab", visible: :all)
    expect(tab["aria-controls"]).to eq("overview-panel")
    panel = page.find("#overview-panel", visible: :all)
    expect(panel["aria-labelledby"]).to eq("overview-tab")
    expect(render_tabs.to_html).to eq(render_tabs.to_html)
  end

  it "selects the first tab by default: roving tabindex, aria-selected, only its panel visible" do
    render_tabs
    expect(page.find("#overview-tab", visible: :all)["aria-selected"]).to eq("true")
    expect(page.find("#overview-tab", visible: :all)[:tabindex]).to eq("0")
    expect(page.find("#crew-tab", visible: :all)["aria-selected"]).to eq("false")
    expect(page.find("#crew-tab", visible: :all)[:tabindex]).to eq("-1")
    expect(page).to have_css("#overview-panel:not([hidden])", visible: :all)
    expect(page).to have_css("#crew-panel[hidden]", visible: :all)
    expect(page).to have_css("#cargo-panel[hidden]", visible: :all)
  end

  it "can select another tab on the server" do
    render_tabs(selected: "crew")
    expect(page.find("#crew-tab", visible: :all)["aria-selected"]).to eq("true")
    expect(page).to have_css("#crew-panel:not([hidden])", visible: :all)
    expect(page).to have_css("#overview-panel[hidden]", visible: :all)
  end

  it "makes panels focusable so keyboard users can reach their content" do
    render_tabs
    expect(page.find("#overview-panel", visible: :all)[:tabindex]).to eq("0")
  end

  it "wires the controller actions and targets" do
    render_tabs
    tab = page.find("#crew-tab", visible: :all)
    expect(tab["data-dp-tabs-target"]).to eq("tab")
    expect(tab["data-action"]).to include("click->dp-tabs#select", "keydown->dp-tabs#keydown")
    expect(page.find("#crew-panel", visible: :all)["data-dp-tabs-target"]).to eq("panel")
  end

  it "can sync the selected tab with the URL hash" do
    render_tabs(hash: true)
    expect(page.find(".dp-tabs", visible: :all)["data-dp-tabs-hash-value"]).to eq("true")
  end

  it "passes html options through" do
    render_tabs(class: "x", color: :info)
    expect(page).to have_css(".dp-tabs.x.dp-c-info", visible: :all)
  end

  it "rejects invalid input" do
    expect { render_inline(described_class.new) { |t| t.with_tab(label: "", id: "a") { "x" } } }.to raise_error(ArgumentError, /label/)
    expect { render_inline(described_class.new) { |t| t.with_tab(label: "A", id: "") { "x" } } }.to raise_error(ArgumentError, /id/)
    expect { render_inline(described_class.new) { |t| t.with_tab(label: "A", id: "a") { "x" }; t.with_tab(label: "B", id: "a") { "y" } } }.to raise_error(ArgumentError, /unique|duplicate/)
    expect { render_tabs(selected: "nope") }.to raise_error(ArgumentError, /selected.*nope/)
    expect { render_inline(described_class.new) }.to raise_error(ArgumentError, /tab/)
  end
end
