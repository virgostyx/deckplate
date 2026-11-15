require "spec_helper"

RSpec.describe Deckplate::Data::StatusPillComponent, type: :component do
  def pill = page.find(".dp-status-pill")

  {
    ok: [ "success", "OK" ], warn: [ "warning", "Warning" ], fail: [ "danger", "Failed" ],
    idle: [ "muted", "Idle" ], info: [ "info", "Info" ]
  }.each do |status, (role, text)|
    it "renders #{status} with its colour role, an icon and the text #{text.inspect}" do
      render_inline(described_class.new(status:))
      expect(pill[:class].split).to include("dp-status-pill--#{status}", "dp-c-#{role}")
      expect(pill).to have_css("svg.dp-icon[aria-hidden='true']")
      expect(pill).to have_css(".dp-status-pill__label", text: text)
    end
  end

  it "uses a different icon per status, so the status is not carried by colour alone" do
    icons = %i[ok warn fail idle info].map do |status|
      render_inline(described_class.new(status:))
      page.find(".dp-status-pill svg").native.to_html[/<path d="([^"]+)"/, 1]
    end
    expect(icons.uniq.size).to eq(5)
  end

  it "takes a custom label, and translates the default one" do
    render_inline(described_class.new(status: :ok, label: "Nominal"))
    expect(pill).to have_css(".dp-status-pill__label", text: "Nominal")
    I18n.with_locale(:fr) { render_inline(described_class.new(status: :fail)) }
    expect(pill).to have_css(".dp-status-pill__label", text: "Échec")
  end

  it "passes html options through" do
    render_inline(described_class.new(status: :ok, class: "x", data: { a: 1 }, id: "p1"))
    expect(page).to have_css("#p1.dp-status-pill.x[data-a='1']")
  end

  it "rejects an unknown status and an empty label" do
    expect { described_class.new(status: :broken) }.to raise_error(ArgumentError, /status.*ok, warn, fail, idle, info/)
    expect { described_class.new(status: :ok, label: "") }.to raise_error(ArgumentError, /label/)
  end
end
