require "spec_helper"

RSpec.describe Deckplate::Layout::PanelComponent, type: :component do
  it "renders a titled panel with a header bar and a body" do
    render_inline(described_class.new(title: "Power")) { "Reactor output" }
    expect(page).to have_css("section.dp-panel.dp-panel--none.dp-c-primary")
    expect(page).to have_css(".dp-panel__header h2.dp-panel__title", text: "Power")
    expect(page).to have_css(".dp-panel__body", text: "Reactor output")
    expect(page).not_to have_css(".dp-elbow")
    expect(page).not_to have_css(".dp-panel__footer")
  end

  it "renders header actions and a footer" do
    render_inline(described_class.new(title: "T")) do |p|
      p.with_header_actions { "Edit" }
      p.with_footer { "Updated now" }
      "body"
    end
    expect(page).to have_css(".dp-panel__header .dp-panel__actions", text: "Edit")
    expect(page).to have_css(".dp-panel__footer", text: "Updated now")
  end

  describe "corners" do
    it "closes the left side with two elbows and a rail" do
      render_inline(described_class.new(title: "T", corners: :left)) { "x" }
      expect(page).to have_css(".dp-panel--left .dp-elbow--top-start")
      expect(page).to have_css(".dp-panel--left .dp-elbow--bottom-start")
      expect(page).not_to have_css(".dp-elbow--top-end")
      expect(page).to have_css(".dp-panel__rail", count: 1)
      expect(page).to have_css(".dp-panel__footer") # the bottom bar always exists when there are corners
    end

    it "draws its elbows with logical corners, so the panel mirrors in right-to-left text (ADR 0017)" do
      render_inline(described_class.new(title: "T", corners: :both)) { "x" }
      expect(page).to have_css(".dp-elbow--top-start, .dp-elbow--top-end, .dp-elbow--bottom-start, .dp-elbow--bottom-end", count: 4)
      expect(page).not_to have_css(".dp-elbow--top-left, .dp-elbow--top-right, .dp-elbow--bottom-left, .dp-elbow--bottom-right")
    end

    it "accepts :start as the name of the left variant (the side where the text starts)" do
      render_inline(described_class.new(title: "T", corners: :start)) { "x" }
      expect(page).to have_css(".dp-panel--left .dp-elbow--top-start")
    end

    it "closes both sides with four elbows and two rails" do
      render_inline(described_class.new(title: "T", corners: :both)) { "x" }
      expect(page).to have_css(".dp-elbow", count: 4)
      expect(page).to have_css(".dp-panel__rail", count: 2)
    end

    it "gives the elbows the panel colour" do
      render_inline(described_class.new(title: "T", corners: :left, color: :info)) { "x" }
      expect(page).to have_css(".dp-elbow.dp-c-info", count: 2)
    end
  end

  it "names the panel by its title when an id is given" do
    render_inline(described_class.new(title: "Power", id: "pw")) { "x" }
    expect(page).to have_css("section#pw[aria-labelledby='pw-title'] #pw-title", text: "Power")
  end

  it "supports colour, heading level and html options" do
    render_inline(described_class.new(title: "T", color: :tertiary, level: 3, class: "x", data: { a: 1 })) { "x" }
    expect(page).to have_css("section.dp-panel.dp-c-tertiary.x[data-a='1'] h3.dp-panel__title")
  end

  it "rejects invalid input" do
    expect { described_class.new(title: "") }.to raise_error(ArgumentError, /title/)
    expect { described_class.new(title: "T", corners: :top) }.to raise_error(ArgumentError, /corners.*none, left, both/)
    expect { described_class.new(title: "T", level: 9) }.to raise_error(ArgumentError, /level/)
    expect { described_class.new(title: "T", color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
