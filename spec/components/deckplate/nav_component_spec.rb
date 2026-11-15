require "spec_helper"

RSpec.describe Deckplate::NavComponent, type: :component do
  def render_nav(path: "/", **opts, &block)
    with_request_url(path) do
      render_inline(described_class.new(**opts)) do |n|
        n.with_item(label: "Overview", href: "/", number: "01", color: :primary)
        n.with_item(label: "Ships", href: "/ships", number: "02")
        n.with_item(label: "Crew", href: "/crew")
        block&.call(n)
      end
    end
  end

  it "renders a labelled nav landmark with a list of links" do
    render_nav
    expect(page).to have_css("nav.dp-nav[aria-label='Main navigation'] ul.dp-nav__list li.dp-nav__item a.dp-nav__link", count: 3)
    expect(page).to have_css("a.dp-nav__link[href='/ships'] .dp-nav__label", text: "Ships")
  end

  it "shows the optional number before the label" do
    render_nav
    expect(page).to have_css("a[href='/'] .dp-nav__number", text: "01")
    expect(page).not_to have_css("a[href='/crew'] .dp-nav__number")
  end

  it "uses the translated landmark label, or the given one" do
    I18n.with_locale(:fr) { render_nav }
    expect(page).to have_css("nav[aria-label='Navigation principale']")
    render_nav(label: "Decks")
    expect(page).to have_css("nav[aria-label='Decks']")
  end

  describe "current page" do
    it "marks the link of the current page with aria-current" do
      render_nav(path: "/ships")
      expect(page).to have_css("a[href='/ships'][aria-current='page'].dp-nav__link--current")
      expect(page).not_to have_css("a[href='/'][aria-current]")
      expect(page).to have_css("[aria-current='page']", count: 1)
    end

    it "does not mark anything on an unrelated page" do
      render_nav(path: "/elsewhere")
      expect(page).not_to have_css("[aria-current]")
    end

    it "lets the caller force it" do
      with_request_url("/") do
        render_inline(described_class.new) do |n|
          n.with_item(label: "A", href: "/", current: false)
          n.with_item(label: "B", href: "/b", current: true)
        end
      end
      expect(page).to have_css("a[href='/b'][aria-current='page']")
      expect(page).not_to have_css("a[href='/'][aria-current]")
    end
  end

  it "applies colours to items" do
    render_nav
    expect(page).to have_css("a[href='/'].dp-c-primary")
    expect(page).to have_css("a[href='/ships'].dp-c-tertiary") # default
  end

  it "passes html options through" do
    render_nav(class: "x", data: { a: 1 })
    expect(page).to have_css("nav.dp-nav.x[data-a='1']")
  end

  it "rejects invalid item input" do
    expect { Deckplate::NavItemComponent.new(label: "", href: "/") }.to raise_error(ArgumentError, /label/)
    expect { Deckplate::NavItemComponent.new(label: "A", href: "") }.to raise_error(ArgumentError, /href/)
    expect { Deckplate::NavItemComponent.new(label: "A", href: "/", color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
