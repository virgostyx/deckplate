require "spec_helper"

RSpec.describe Deckplate::ButtonComponent, type: :component do
  def button = page.find(".dp-button")

  describe "default rendering" do
    before { render_inline(described_class.new(label: "Engage")) }

    it "renders a pill button of medium size in the primary colour" do
      expect(page).to have_css("button.dp-button", text: "Engage")
      expect(button[:class].split).to include("dp-button--pill", "dp-button--md", "dp-c-primary")
    end

    it "is a non-submitting button unless told otherwise" do
      expect(button[:type]).to eq("button")
    end

    it "wraps the label in an element the CSS can style" do
      expect(page).to have_css(".dp-button .dp-button__label", text: "Engage")
    end
  end

  it "takes the label from the block when no label: is given" do
    render_inline(described_class.new) { "From block" }
    expect(page).to have_css(".dp-button__label", text: "From block")
  end

  it "supports every shape, size and a palette colour" do
    %i[pill block start end].each do |shape|
      render_inline(described_class.new(label: "x", shape:))
      expect(page).to have_css(".dp-button.dp-button--#{shape}")
    end
    %i[xs sm md lg xl].each do |size|
      render_inline(described_class.new(label: "x", size:))
      expect(page).to have_css(".dp-button.dp-button--#{size}")
    end
    render_inline(described_class.new(label: "x", color: :neon_carrot))
    expect(button[:class].split).to include("dp-c-neon-carrot")
  end

  it "supports the submit and reset types" do
    render_inline(described_class.new(label: "Go", type: "submit"))
    expect(button[:type]).to eq("submit")
    render_inline(described_class.new(label: "Go", type: :reset))
    expect(button[:type]).to eq("reset")
  end

  describe "as a link" do
    it "renders an anchor when href: is given" do
      render_inline(described_class.new(label: "Docs", href: "/docs"))
      expect(page).to have_css("a.dp-button[href='/docs']", text: "Docs")
      expect(page).not_to have_css("button.dp-button")
    end

    it "keeps the link semantics but is inert when disabled" do
      render_inline(described_class.new(label: "Docs", href: "/docs", disabled: true))
      a = page.find("a.dp-button")
      expect(a[:href]).to be_nil
      expect(a["aria-disabled"]).to eq("true")
      expect(a[:tabindex]).to eq("-1")
      expect(a[:role]).to eq("link")
    end
  end

  describe "with a non-GET method" do
    it "renders a form around the button (button_to)" do
      render_inline(described_class.new(label: "Delete", href: "/ships/1", method: :delete, color: :danger))
      form = page.find("form.dp-button-form", visible: :all)
      expect(form[:action]).to eq("/ships/1")
      expect(form[:method]).to eq("post")
      expect(page).to have_css("form input[name='_method'][value='delete']", visible: :all)
      expect(page).to have_css("form button.dp-button.dp-c-danger", text: "Delete")
    end

    it "requires an href" do
      expect { described_class.new(label: "x", method: :delete) }.to raise_error(ArgumentError, /method.*href/)
    end
  end

  describe "icon" do
    it "renders a decorative icon before the label" do
      render_inline(described_class.new(label: "Search", icon: :search))
      expect(page).to have_css(".dp-button svg.dp-icon[aria-hidden='true']")
      expect(button.native.inner_html).to match(/<svg.*<span class="dp-button__label">/m)
    end

    it "rejects unknown icons" do
      expect { render_inline(described_class.new(label: "x", icon: :nope)) }.to raise_error(ArgumentError, /unknown icon/)
    end
  end

  describe "states" do
    it "disables a real button" do
      render_inline(described_class.new(label: "x", disabled: true))
      expect(button[:disabled]).not_to be_nil
    end

    it "marks loading as busy and unavailable, with a text alternative for assistive tech" do
      render_inline(described_class.new(label: "Save", loading: true))
      expect(button["aria-busy"]).to eq("true")
      expect(button["aria-disabled"]).to eq("true")
      expect(button[:class].split).to include("dp-button--loading")
      expect(page).to have_css(".dp-button__spinner[aria-hidden='true']")
      expect(page).to have_css(".dp-button .dp-sr-only", text: "Loading")
    end

    it "translates the loading text" do
      I18n.with_locale(:fr) { render_inline(described_class.new(label: "Save", loading: true)) }
      expect(page).to have_css(".dp-sr-only", text: "Chargement")
    end
  end

  it "passes class, data, aria and id through" do
    render_inline(described_class.new(label: "x", class: "extra", data: { turbo_confirm: "Sure?" }, aria: { describedby: "h" }, id: "b1"))
    expect(page).to have_css("button#b1.dp-button.extra[data-turbo-confirm='Sure?'][aria-describedby='h']")
  end

  it "needs a label or a block" do
    expect { render_inline(described_class.new) }.to raise_error(ArgumentError, /label/)
  end

  it "rejects invalid options" do
    expect { described_class.new(label: "x", shape: :round) }.to raise_error(ArgumentError, /shape/)
    expect { described_class.new(label: "x", size: :huge) }.to raise_error(ArgumentError, /size.*xs, sm, md, lg, xl/)
    expect { described_class.new(label: "x", type: "link") }.to raise_error(ArgumentError, /type.*button, submit, reset/)
    expect { described_class.new(label: "x", color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
    expect { described_class.new(label: "x", method: :fetch, href: "/") }.to raise_error(ArgumentError, /method/)
  end
end
