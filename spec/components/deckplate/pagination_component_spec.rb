require "spec_helper"

RSpec.describe Deckplate::PaginationComponent, type: :component do
  let(:url_for) { ->(page) { "/ships?page=#{page}" } }

  def render_page(page:, pages:, **opts)
    render_inline(described_class.new(page:, pages:, url_for:, **opts))
  end

  it "renders a labelled nav with previous, numbered pages and next" do
    render_page(page: 2, pages: 5)
    expect(page).to have_css("nav.dp-pagination[aria-label='Pagination'] ul li")
    expect(page).to have_css("a[rel='prev'][href='/ships?page=1'][aria-label='Previous page']")
    expect(page).to have_css("a[rel='next'][href='/ships?page=3'][aria-label='Next page']")
    (1..5).each { |n| expect(page).to have_css("li", text: n.to_s) }
  end

  it "marks the current page and names it for assistive tech" do
    render_page(page: 3, pages: 5)
    current = page.find("[aria-current='page']")
    expect(current.text).to eq("3")
    expect(current["aria-label"]).to eq("Page 3, current page")
    expect(page).to have_css("[aria-current='page']", count: 1)
    expect(page).to have_css("a[href='/ships?page=4'][aria-label='Page 4']")
  end

  it "disables previous on the first page and next on the last, without making them links" do
    render_page(page: 1, pages: 3)
    expect(page).not_to have_css("a[rel='prev']")
    expect(page).to have_css("span.dp-pagination__link[aria-disabled='true']", text: /prev|‹|‹/i, visible: :all)
    render_page(page: 3, pages: 3)
    expect(page).not_to have_css("a[rel='next']")
  end

  it "collapses long ranges with ellipses around a window of the current page" do
    render_page(page: 10, pages: 20, window: 1)
    labels = page.all("li").map { _1.text.strip }
    expect(labels).to include("1", "9", "10", "11", "20", "…")
    expect(labels).not_to include("5", "15")
    expect(page).to have_css("li[aria-hidden='true']", text: "…", count: 2)
  end

  it "shows all pages when they fit in the window" do
    render_page(page: 1, pages: 4, window: 2)
    expect(page).not_to have_content("…")
  end

  it "renders nothing for a single page" do
    render_page(page: 1, pages: 1)
    expect(page).not_to have_css("nav")
  end

  it "translates labels" do
    I18n.with_locale(:fr) { render_page(page: 2, pages: 3) }
    expect(page).to have_css("nav[aria-label='Pagination'] a[aria-label='Page précédente']")
    expect(page).to have_css("[aria-current='page'][aria-label='Page 2, page courante']")
  end

  it "passes html options through" do
    render_page(page: 1, pages: 3, class: "x")
    expect(page).to have_css("nav.dp-pagination.x")
  end

  it "rejects invalid input" do
    expect { described_class.new(page: 0, pages: 3, url_for:) }.to raise_error(ArgumentError, /page/)
    expect { described_class.new(page: 4, pages: 3, url_for:) }.to raise_error(ArgumentError, /page/)
    expect { described_class.new(page: 1, pages: 0, url_for:) }.to raise_error(ArgumentError, /pages/)
    expect { described_class.new(page: 1, pages: 3, url_for: "x") }.to raise_error(ArgumentError, /url_for/)
    expect { described_class.new(page: 1, pages: 3, url_for:, window: -1) }.to raise_error(ArgumentError, /window/)
  end
end
