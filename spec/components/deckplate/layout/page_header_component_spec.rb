require "spec_helper"

RSpec.describe Deckplate::Layout::PageHeaderComponent, type: :component do
  it "renders a header with an h1 title" do
    render_inline(described_class.new(title: "Sensor array"))
    expect(page).to have_css("header.dp-page-header h1.dp-page-header__title", text: "Sensor array")
    expect(page).not_to have_css(".dp-page-header__subtitle")
  end

  it "shows a subtitle" do
    render_inline(described_class.new(title: "T", subtitle: "Deck 4"))
    expect(page).to have_css("p.dp-page-header__subtitle", text: "Deck 4")
  end

  it "uses the requested heading level" do
    render_inline(described_class.new(title: "T", level: 2))
    expect(page).to have_css("h2.dp-page-header__title")
  end

  it "renders actions and breadcrumb slots" do
    render_inline(described_class.new(title: "T")) do |h|
      h.with_breadcrumb { "Home / Ships" }
      h.with_actions { "Act" }
    end
    expect(page).to have_css(".dp-page-header__breadcrumb", text: "Home / Ships")
    expect(page).to have_css(".dp-page-header__actions", text: "Act")
  end

  it "renders no empty slot wrappers" do
    render_inline(described_class.new(title: "T"))
    expect(page).not_to have_css(".dp-page-header__actions")
    expect(page).not_to have_css(".dp-page-header__breadcrumb")
  end

  it "passes class, data and id through" do
    render_inline(described_class.new(title: "T", class: "x", data: { a: 1 }, id: "ph"))
    expect(page).to have_css("header#ph.dp-page-header.x[data-a='1']")
  end

  it "rejects missing titles and bad levels" do
    expect { described_class.new(title: "") }.to raise_error(ArgumentError, /title/)
    expect { described_class.new(title: nil) }.to raise_error(ArgumentError, /title/)
    expect { described_class.new(title: "T", level: 7) }.to raise_error(ArgumentError, /level.*1.*6/)
  end
end
