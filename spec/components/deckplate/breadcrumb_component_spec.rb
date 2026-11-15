require "spec_helper"

RSpec.describe Deckplate::BreadcrumbComponent, type: :component do
  let(:items) { [ [ "Home", "/" ], [ "Ships", "/ships" ], [ "Aurora" ] ] }

  it "renders an ordered list of links, the last item being the current page" do
    render_inline(described_class.new(items:))
    expect(page).to have_css("nav.dp-breadcrumb[aria-label='Breadcrumb'] ol li", count: 3)
    expect(page).to have_css("li a[href='/']", text: "Home")
    expect(page).to have_css("li a[href='/ships']", text: "Ships")
    expect(page).to have_css("li[aria-current='page']", text: "Aurora")
    expect(page).not_to have_css("li[aria-current='page'] a")
  end

  it "accepts hashes, and never links the last item even when it has an href" do
    render_inline(described_class.new(items: [ { label: "Home", href: "/" }, { label: "Here", href: "/here" } ]))
    expect(page).to have_css("li a[href='/']")
    expect(page).not_to have_css("a[href='/here']")
    expect(page).to have_css("li[aria-current='page']", text: "Here")
  end

  it "renders a single item" do
    render_inline(described_class.new(items: [ [ "Home" ] ]))
    expect(page).to have_css("li[aria-current='page']", text: "Home")
  end

  it "translates the landmark label" do
    I18n.with_locale(:fr) { render_inline(described_class.new(items:)) }
    expect(page).to have_css("nav[aria-label=\"Fil d'Ariane\"]")
  end

  it "passes html options through" do
    render_inline(described_class.new(items:, class: "x"))
    expect(page).to have_css("nav.dp-breadcrumb.x")
  end

  it "rejects empty or malformed items" do
    expect { described_class.new(items: []) }.to raise_error(ArgumentError, /items/)
    expect { described_class.new(items: [ [ "", "/" ] ]) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(items: [ 42 ]) }.to raise_error(ArgumentError, /item/)
  end
end
