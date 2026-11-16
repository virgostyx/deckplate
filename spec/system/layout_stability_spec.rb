require "spec_helper"

# Cumulative layout shift while the page loads and the web fonts swap in (ADR 0015). Budget: < 0.02 (the "good" CLS threshold is 0.1).
RSpec.describe "Layout stability", type: :system, js: true do
  PAGES = %w[frame/classic classic_console/default data_list/default text_input/default].freeze

  before do
    driven_by :dp_cuprite
    page.driver.browser.evaluate_on_new_document(<<~JS)
      window.__cls = 0
      new PerformanceObserver((list) => { for (const e of list.getEntries()) if (!e.hadRecentInput) window.__cls += e.value })
        .observe({ type: "layout-shift", buffered: true })
    JS
  end

  # Fonts arrive late (the case that matters): the text first shows in the local fallback, then swaps.
  def delay_fonts
    browser = page.driver.browser
    browser.network.intercept
    browser.on(:request) do |request|
      if request.url.include?(".woff2")
        Thread.new { sleep 0.8; request.continue }
      else
        request.continue
      end
    end
  end

  PAGES.each do |path|
    it "#{path} shifts less than 0.02 from first paint to fonts loaded" do
      delay_fonts
      visit "/rails/view_components/#{path}"
      expect(page).to have_css(".dp-root .dp-root, .dp-root > *", wait: 5) # a real preview rendered, not an error page
      expect(page).not_to have_content("Routing Error")
      page.evaluate_async_script("document.fonts.ready.then(() => setTimeout(arguments[0], 400))")
      expect(page.evaluate_script("document.fonts.check('16px Antonio')")).to be(true)
      expect(page.evaluate_script("window.__cls")).to be < 0.02
    end
  end
end
