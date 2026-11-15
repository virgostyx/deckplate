require "spec_helper"

RSpec.describe Deckplate::ModalComponent, type: :component do
  def render_modal(**opts, &block)
    render_inline(described_class.new(title: "Confirm", id: "confirm", **opts)) do |m|
      m.with_trigger { '<button type="button" data-action="dp-modal#open">Open</button>'.html_safe }
      m.with_actions { '<button type="button">OK</button>'.html_safe }
      block&.call(m)
      "Are you sure?"
    end
  end

  it "renders a native dialog named by its title, inside a controller wrapper" do
    render_modal
    expect(page).to have_css(".dp-modal-host[data-controller='dp-modal']", visible: :all)
    dialog = page.find("dialog#confirm.dp-modal", visible: :all)
    expect(dialog["aria-labelledby"]).to eq("confirm-title")
    expect(page.find("#confirm-title", visible: :all).text(:all)).to eq("Confirm")
    expect(page).to have_css("dialog .dp-modal__body", text: "Are you sure?", visible: :all)
    expect(dialog[:open]).to be_nil
  end

  it "renders the trigger outside the dialog and the actions inside it" do
    render_modal
    expect(page).to have_css(".dp-modal-host > button[data-action='dp-modal#open']", text: "Open", visible: :all)
    expect(page).to have_css("dialog .dp-modal__actions button", text: "OK", visible: :all)
  end

  it "has a translated close button" do
    render_modal
    close = page.find("dialog .dp-modal__close", visible: :all)
    expect(close["aria-label"]).to eq("Close")
    expect(close["data-action"]).to eq("dp-modal#close")
    I18n.with_locale(:fr) { render_modal }
    expect(page.find("dialog .dp-modal__close", visible: :all)["aria-label"]).to eq("Fermer")
  end

  it "wires the dialog events" do
    render_modal
    actions = page.find("dialog", visible: :all)["data-action"]
    expect(actions).to include("click->dp-modal#backdrop", "close->dp-modal#closed", "turbo:submit-end->dp-modal#submitEnd")
    expect(page.find("dialog", visible: :all)["data-dp-modal-target"]).to eq("dialog")
  end

  it "supports sizes and an initially open state" do
    %i[sm md lg].each do |size|
      render_modal(size:)
      expect(page).to have_css("dialog.dp-modal--#{size}", visible: :all)
    end
    render_modal(open: true)
    expect(page.find(".dp-modal-host", visible: :all)["data-dp-modal-open-value"]).to eq("true")
  end

  it "derives an id from the title when none is given" do
    render_inline(described_class.new(title: "Delete ship")) { "x" }
    expect(page).to have_css("dialog#delete-ship-modal", visible: :all)
  end

  it "passes html options to the wrapper" do
    render_modal(class: "x", data: { a: 1 })
    expect(page).to have_css(".dp-modal-host.x[data-a='1']", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(title: "") }.to raise_error(ArgumentError, /title/)
    expect { described_class.new(title: "T", size: :xl) }.to raise_error(ArgumentError, /size.*sm, md, lg/)
  end
end
