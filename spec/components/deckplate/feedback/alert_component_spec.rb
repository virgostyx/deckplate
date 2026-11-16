require "spec_helper"

RSpec.describe Deckplate::Feedback::AlertComponent, type: :component do
  def alert = page.find(".dp-alert")

  {
    info: [ "status", "info", "Information" ], success: [ "status", "success", "Success" ],
    warning: [ "alert", "warning", "Warning" ], danger: [ "alert", "danger", "Error" ]
  }.each do |kind, (role, color, word)|
    it "renders #{kind} with role=#{role}, the #{color} colour, an icon and the word #{word.inspect}" do
      render_inline(described_class.new(kind:)) { "Something happened" }
      expect(alert[:role]).to eq(role)
      expect(alert[:class].split).to include("dp-alert--#{kind}", "dp-c-#{color}")
      expect(alert).to have_css("svg.dp-icon[aria-hidden='true']")
      expect(alert).to have_css(".dp-sr-only", text: word)
      expect(alert).to have_css(".dp-alert__body", text: "Something happened")
    end
  end

  it "uses a different icon for each kind (the kind is not carried by colour alone)" do
    icons = %i[info success warning danger].map do |kind|
      render_inline(described_class.new(kind:)) { "x" }
      page.find(".dp-alert svg").native.to_html[/<path d="([^"]+)"/, 1]
    end
    expect(icons.uniq.size).to eq(4)
  end

  it "defaults to info" do
    render_inline(described_class.new) { "x" }
    expect(alert[:class].split).to include("dp-alert--info")
  end

  it "translates the kind word" do
    I18n.with_locale(:fr) { render_inline(described_class.new(kind: :danger)) { "x" } }
    expect(alert).to have_css(".dp-sr-only", text: "Erreur")
  end

  it "shows an optional title" do
    render_inline(described_class.new(title: "Heads up")) { "x" }
    expect(alert).to have_css(".dp-alert__title", text: "Heads up")
  end

  describe "dismissible" do
    it "is not dismissible by default" do
      render_inline(described_class.new) { "x" }
      expect(page).not_to have_css(".dp-alert__close")
      expect(alert["data-controller"]).to be_nil
    end

    it "renders a translated close button wired to dp-dismiss" do
      render_inline(described_class.new(dismissible: true)) { "x" }
      expect(alert["data-controller"]).to eq("dp-dismiss")
      close = alert.find("button.dp-alert__close")
      expect(close[:type]).to eq("button")
      expect(close["aria-label"]).to eq("Close")
      expect(close["data-action"]).to eq("dp-dismiss#dismiss")
      I18n.with_locale(:fr) { render_inline(described_class.new(dismissible: true)) { "x" } }
      expect(alert.find("button")["aria-label"]).to eq("Fermer")
    end
  end

  it "passes html options through (a stable id lets a Turbo Stream replace it)" do
    render_inline(described_class.new(id: "a1", class: "x", data: { a: 1 })) { "x" }
    expect(page).to have_css("#a1.dp-alert.x[data-a='1']")
  end

  it "rejects an unknown kind" do
    expect { described_class.new(kind: :fatal) }.to raise_error(ArgumentError, /kind.*info, success, warning, danger/)
  end
end
