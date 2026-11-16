require "spec_helper"

RSpec.describe Deckplate::Feedback::EmptyStateComponent, type: :component do
  it "renders a title, a hint and an action" do
    render_inline(described_class.new(title: "No ships yet", hint: "Register your first ship.")) { |e| e.with_action { '<a href="/new">Add a ship</a>'.html_safe } }
    expect(page).to have_css(".dp-empty-state h2.dp-empty-state__title", text: "No ships yet")
    expect(page).to have_css(".dp-empty-state__hint", text: "Register your first ship.")
    expect(page).to have_css(".dp-empty-state__action a[href='/new']", text: "Add a ship")
  end

  it "renders only what it is given" do
    render_inline(described_class.new(title: "Nothing"))
    expect(page).not_to have_css(".dp-empty-state__hint")
    expect(page).not_to have_css(".dp-empty-state__action")
  end

  it "takes a heading level and an optional decorative icon" do
    render_inline(described_class.new(title: "T", level: 3, icon: :search))
    expect(page).to have_css("h3.dp-empty-state__title")
    expect(page).to have_css(".dp-empty-state svg.dp-icon[aria-hidden='true']")
  end

  it "passes html options through" do
    render_inline(described_class.new(title: "T", class: "x", id: "es"))
    expect(page).to have_css("#es.dp-empty-state.x")
  end

  it "rejects invalid input" do
    expect { described_class.new(title: "") }.to raise_error(ArgumentError, /title/)
    expect { described_class.new(title: "T", level: 8) }.to raise_error(ArgumentError, /level/)
    expect { described_class.new(title: "T", icon: :nope) }.to raise_error(ArgumentError, /icon/)
  end
end
