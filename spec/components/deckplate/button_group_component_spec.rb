require "spec_helper"

RSpec.describe Deckplate::ButtonGroupComponent, type: :component do
  it "groups its content with the group role" do
    render_inline(described_class.new) { "<button>A</button><button>B</button>".html_safe }
    expect(page).to have_css("div.dp-button-group.dp-button-group--horizontal[role='group'] button", count: 2)
  end

  it "supports the vertical orientation" do
    render_inline(described_class.new(orientation: :vertical)) { "x" }
    expect(page).to have_css(".dp-button-group.dp-button-group--vertical")
  end

  it "can be named for assistive tech" do
    render_inline(described_class.new(label: "Ship actions")) { "x" }
    expect(page).to have_css(".dp-button-group[aria-label='Ship actions']")
  end

  it "passes html options through" do
    render_inline(described_class.new(class: "x", data: { a: 1 })) { "x" }
    expect(page).to have_css(".dp-button-group.x[data-a='1']")
  end

  it "rejects an invalid orientation" do
    expect { described_class.new(orientation: :diagonal) }.to raise_error(ArgumentError, /orientation.*horizontal, vertical/)
  end
end
