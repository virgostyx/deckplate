require "spec_helper"

RSpec.describe Deckplate::TopNavComponent, type: :component do
  it "renders a secondary navigation with its own landmark label" do
    with_request_url("/b") do
      render_inline(described_class.new) do |n|
        n.with_item(label: "A", href: "/a")
        n.with_item(label: "B", href: "/b")
      end
    end
    expect(page).to have_css("nav.dp-top-nav[aria-label='Secondary navigation'] li.dp-nav__item", count: 2)
    expect(page).to have_css("a[href='/b'][aria-current='page']")
  end

  it "can be labelled and translated" do
    render_inline(described_class.new(label: "Reports")) { |n| n.with_item(label: "A", href: "/a") }
    expect(page).to have_css("nav[aria-label='Reports']")
    I18n.with_locale(:fr) { render_inline(described_class.new) { |n| n.with_item(label: "A", href: "/a") } }
    expect(page).to have_css("nav[aria-label='Navigation secondaire']")
  end
end
